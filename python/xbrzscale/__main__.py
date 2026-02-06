"""
Command-line interface for xbrzscale
"""

import sys
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

from .wrapper import scale_image, get_version


def main():
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(
        description="Scale pixel art images using the xBRZ algorithm",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  xbrzscale-py 4 input.png output.png     Scale input.png by 4x
  xbrzscale-py 2 sprite.bmp sprite_2x.png Scale sprite.bmp by 2x

The scale factor must be between 2 and 6 (inclusive).
Output is always saved as PNG format.
        """
    )

    parser.add_argument(
        "scale",
        type=int,
        help="Scale factor (2-6)"
    )
    parser.add_argument(
        "input",
        type=str,
        help="Input image file"
    )
    parser.add_argument(
        "output",
        type=str,
        help="Output image file (PNG)"
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"xbrzscale {get_version()}"
    )

    args = parser.parse_args()

    # Validate scale factor
    if args.scale < 2 or args.scale > 6:
        print(f"Error: scale_factor must be between 2 and 6 (inclusive), got {args.scale}",
              file=sys.stderr)
        return 1

    # Check input file exists
    input_path = Path(args.input)
    if not input_path.is_file():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        return 1

    # Load image
    try:
        print(f"Loading image from {args.input}...")
        img = Image.open(args.input)

        # Convert to RGBA
        if img.mode != "RGBA":
            img = img.convert("RGBA")

        img_array = np.array(img)
        print(f"Image size: {img_array.shape[1]}x{img_array.shape[0]}")

    except Exception as e:
        print(f"Error: Failed to load image: {e}", file=sys.stderr)
        return 1

    # Scale image
    try:
        print(f"Scaling image by {args.scale}x...")
        scaled = scale_image(img_array, args.scale)
        print(f"Scaled size: {scaled.shape[1]}x{scaled.shape[0]}")

    except Exception as e:
        print(f"Error: Scaling failed: {e}", file=sys.stderr)
        return 1

    # Save output
    try:
        print(f"Saving image to {args.output}...")
        output_img = Image.fromarray(scaled, "RGBA")
        output_img.save(args.output, "PNG")
        print("Done!")

    except Exception as e:
        print(f"Error: Failed to save image: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
