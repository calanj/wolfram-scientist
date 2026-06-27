(* ============================================================
   dataProvenance.wl
   Provenance-tracked external-data acquisition for the Wolfram Scientist.

   The Scientist increasingly runs *empirical* studies on data pulled from
   OUTSIDE Wolfram's curated knowledge base — a USGS earthquake query, a FRED
   series, a GBIF download, an arbitrary dataset URL, or a file a user attached
   to a GitHub issue. For such a study to be reproducible, every external input
   must be:
     1. cached locally, so a re-run doesn't depend on the source still being live;
     2. fingerprinted (SHA-256), so silent upstream drift is detectable;
     3. recorded with its origin, fetch time, and shape, so the PR is auditable.
   This file is that discipline, expressed as in-kernel functions.

   Storage policy ("commit small, hash large"): a raw payload at or under the
   size threshold (default 5 MB) is marked for committing into
   research/<id>/inputs/ so the PR is self-contained; a larger payload is cached
   locally but git-ignored, with only its URL + SHA-256 + shape kept in the
   (always-committed) manifest. The threshold is enforced mechanically: this
   file regenerates research/<id>/inputs/.gitignore from the manifest on every
   fetch, so large payloads are never accidentally committed.

   API:
     dataInputsDir[id]         -> "research/<id>/inputs" (created if absent)
     dataFetch[url, dir]       -> acquire url into dir (idempotent); returns the
                                  manifest entry (an Association)
     dataFetch[url, dir, opts] -> options below
     dataLoad[dir, key]        -> Import the cached payload for key, verifying
                                  its SHA-256 against the manifest first
     dataManifest[dir]         -> the list of manifest entries (Associations)

   dataFetch options:
     "Name"      -> cache filename / key  (Automatic: derived from the URL)
     "Source"    -> provenance tag, e.g. "USGS" or "discovery"  (default "discovery")
     "Format"    -> import format used only to record the shape  (Automatic)
     "Threshold" -> commit/no-commit byte cutoff  (default $dataCommitThreshold)
     "Refresh"   -> True re-downloads even if a matching cache exists  (default False)

   Usage:

     << "lib/dataProvenance.wl"
     dir = dataInputsDir["usgs-gutenberg-richter"];
     entry = dataFetch[
       "https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv&\
starttime=2024-01-01&endtime=2024-02-01&minmagnitude=2.5",
       dir, "Name" -> "quakes.csv", "Source" -> "USGS"];
     entry["SHA256"]                      (* fingerprint recorded in manifest.json *)
     data = dataLoad[dir, "quakes.csv"];  (* re-imports from the local cache *)

   Re-running is cheap and safe: dataFetch skips the download when the file is
   already cached AND its hash matches the manifest (use "Refresh"->True to force
   a re-pull). So experiment.wl can call dataFetch at the top and regenerate
   every result from the local cache on each fresh-kernel run, with no network
   round-trip and a guarantee the bytes are the ones the finding was built on.

   Origin: shared infrastructure for issue-fed data sources and open-ended
   empirical studies (2026-06-27).
   ============================================================ *)

(* Default commit/no-commit cutoff: 5 MB. Override per-call via "Threshold". *)
$dataCommitThreshold = 5 * 2^20;

dataInputsDir[id_String] := Module[{dir},
  dir = FileNameJoin[{"research", id, "inputs"}];
  If[! DirectoryQ[dir],
    CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  dir
];

dataManifest[dir_String] := Module[{f},
  f = FileNameJoin[{dir, "manifest.json"}];
  If[FileExistsQ[f], Import[f, "RawJSON"], {}]
];

(* A filesystem-safe cache name from a URL: the last path segment before any
   query string; falls back to a hash-named .dat when the URL has no usable
   basename (e.g. a bare API endpoint). *)
dataNameFromURL[url_String] := Module[{base},
  base = Last[StringSplit[First[StringSplit[url, "?"]], "/"], ""];
  If[base === "" || ! StringContainsQ[base, "."],
    base = "data-" <> IntegerString[Hash[url, "SHA256"], 16, 12] <> ".dat"];
  base
];

(* Best-effort record of the payload's shape for the manifest. Never fatal:
   returns dimensions for tabular/list data, else a short descriptive string. *)
dataShape[path_String, fmt_] := Module[{data},
  data = Quiet@Check[
     If[fmt === Automatic, Import[path], Import[path, fmt]], $Failed];
  Which[
    data === $Failed, "unimported",
    MatrixQ[data], Dimensions[data],
    ListQ[data] && AllTrue[data, ListQ], Dimensions[data],
    ListQ[data], {Length[data]},
    True, "scalar"]
];

(* Rewrite <dir>/.gitignore from the manifest: ignore every cached payload whose
   "Committed" flag is False (over threshold), always keep the manifest tracked.
   This is what makes "commit small, hash large" automatic rather than a thing
   the agent has to remember. *)
dataWriteGitignore[dir_String, entries_List] := Module[{ignored, lines},
  ignored = Cases[entries, e_ /; ! TrueQ[e["Committed"]] :> e["File"]];
  lines = Join[
    {"# Auto-generated by lib/dataProvenance.wl — do not edit by hand.",
     "# Large raw payloads are cached locally but not committed; their URL,",
     "# SHA-256 and shape live in manifest.json (which IS committed)."},
    ignored];
  Export[FileNameJoin[{dir, ".gitignore"}],
    StringRiffle[lines, "\n"] <> "\n", "Text"];
];

Options[dataFetch] = {
  "Name" -> Automatic, "Source" -> Automatic, "Format" -> Automatic,
  "Threshold" :> $dataCommitThreshold, "Refresh" -> False};

dataFetch[url_String, dir_String, opts : OptionsPattern[]] := Module[
  {name, source, fmt, threshold, refresh, entries, existing,
   path, bytes, hash, committed, shape, entry},
  name      = OptionValue["Name"];
  source    = OptionValue["Source"];
  fmt       = OptionValue["Format"];
  threshold = OptionValue["Threshold"];
  refresh   = TrueQ[OptionValue["Refresh"]];
  If[name === Automatic, name = dataNameFromURL[url]];
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  entries  = dataManifest[dir];
  existing = SelectFirst[entries, #["Key"] === name &, Missing[]];
  path     = FileNameJoin[{dir, name}];
  (* Idempotent: a re-run with the cache intact and matching does NOT re-fetch. *)
  If[! refresh && ! MissingQ[existing] && FileExistsQ[path] &&
       FileHash[path, "SHA256", "HexString"] === existing["SHA256"],
    Return[existing]];
  Quiet@Check[URLDownload[url, path], $Failed];
  If[! FileExistsQ[path],
    Message[dataFetch::dl, url]; Return[$Failed]];
  bytes     = FileByteCount[path];
  hash      = FileHash[path, "SHA256", "HexString"];
  committed = bytes <= threshold;
  shape     = dataShape[path, fmt];
  entry = <|
    "Key" -> name, "File" -> name, "URL" -> url,
    "Source" -> If[source === Automatic, "discovery", source],
    "SHA256" -> hash, "Bytes" -> bytes, "Shape" -> shape,
    "FetchedOn" -> DateString["ISODateTime"], "Committed" -> committed|>;
  entries = Append[DeleteCases[entries, e_ /; e["Key"] === name], entry];
  Export[FileNameJoin[{dir, "manifest.json"}], entries, "RawJSON"];
  dataWriteGitignore[dir, entries];
  entry
];

dataFetch::dl = "Download failed for `1` -- nothing cached. Check the URL/network.";

Options[dataLoad] = {"Format" -> Automatic};

dataLoad[dir_String, key_String, opts : OptionsPattern[]] := Module[
  {entries, entry, path, fmt},
  entries = dataManifest[dir];
  entry   = SelectFirst[entries, #["Key"] === key &, Missing[]];
  If[MissingQ[entry],
    Message[dataLoad::nokey, key, dir]; Return[$Failed]];
  path = FileNameJoin[{dir, entry["File"]}];
  If[! FileExistsQ[path],
    Message[dataLoad::nocache, key, entry["URL"]]; Return[$Failed]];
  If[FileHash[path, "SHA256", "HexString"] =!= entry["SHA256"],
    Message[dataLoad::drift, key]];
  fmt = OptionValue["Format"];
  If[fmt === Automatic, Import[path], Import[path, fmt]]
];

dataLoad::nokey   = "No manifest entry with key `1` in `2`. Fetch it first with dataFetch.";
dataLoad::nocache = "Cache for `1` is missing locally (it may be a hash-large payload not committed). Re-fetch from `2`.";
dataLoad::drift   = "Cached payload for `1` no longer matches its recorded SHA-256 -- the local file changed since it was fetched.";
