#!/usr/bin/env python3

import argparse
import subprocess
import tempfile
from pathlib import Path

MODELS = {
    "small": "mlx-community/whisper-small-mlx",
    "medium": "mlx-community/whisper-medium",
    "large": "mlx-community/whisper-large-v3-turbo",
}
MERGED_OUTPUT_NAME = "merged_transcript.txt"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Transcribe audio/video files with MLX Whisper."
    )
    parser.add_argument("files", nargs="+", type=Path, help="Files to transcribe")
    parser.add_argument(
        "--merge",
        action="store_true",
        help=f"Combine every transcript into {MERGED_OUTPUT_NAME}",
    )

    model_group = parser.add_mutually_exclusive_group(required=True)
    model_group.add_argument("--small", action="store_const", const="small", dest="size")
    model_group.add_argument("--medium", action="store_const", const="medium", dest="size")
    model_group.add_argument("--large", action="store_const", const="large", dest="size")

    return parser.parse_args()


def transcribe_one(source: Path, model: str, output_dir: Path, output_name: str) -> Path:
    output_path = output_dir / f"{output_name}.txt"
    command = [
        "mlx_whisper",
        str(source),
        "--model",
        model,
        "--output-name",
        output_name,
        "--output-format",
        "txt",
        "--output-dir",
        str(output_dir),
    ]
    result = subprocess.run(command, check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    if not output_path.is_file():
        raise SystemExit(f"Transcription failed for {source}: no output was created")
    return output_path


def write_separate_transcripts(files: list[Path], model: str, output_dir: Path) -> None:
    stems = [source.stem for source in files]
    duplicate_stems = sorted({stem for stem in stems if stems.count(stem) > 1})
    if duplicate_stems:
        raise SystemExit(
            "Cannot create separate transcripts with duplicate filenames: "
            + ", ".join(duplicate_stems)
        )

    for source in files:
        output_path = transcribe_one(source, model, output_dir, source.stem)
        print(f"Wrote {output_path}")


def write_merged_transcript(files: list[Path], model: str, output_dir: Path) -> None:
    sections = []
    with tempfile.TemporaryDirectory(prefix="mlx-whisper-") as temp_dir:
        temp_path = Path(temp_dir)
        for index, source in enumerate(files, start=1):
            transcript_path = transcribe_one(source, model, temp_path, f"transcript_{index}")
            transcript = transcript_path.read_text(encoding="utf-8").strip()
            title = source.name
            sections.append(f"{title}\n{'=' * len(title)}\n\n{transcript}")

    output_path = output_dir / MERGED_OUTPUT_NAME
    output_path.write_text("\n\n".join(sections) + "\n", encoding="utf-8")
    print(f"Wrote {output_path}")


def main() -> int:
    args = parse_args()
    missing_files = [str(path) for path in args.files if not path.is_file()]
    if missing_files:
        raise SystemExit(f"File not found: {', '.join(missing_files)}")

    output_dir = Path.cwd()
    model = MODELS[args.size]
    if args.merge:
        write_merged_transcript(args.files, model, output_dir)
    else:
        write_separate_transcripts(args.files, model, output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
