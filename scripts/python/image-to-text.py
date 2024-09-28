#  pip install pytesseract pillow and install the tesseract package using your package manager (ex: pacman -S tesseract)
import pytesseract
from PIL import Image
import sys

# Check if an image file is provided as an argument
if len(sys.argv) != 2:
    print("Error: There must be at least one argument")
    sys.exit(1)

# Open the image file
image_path = sys.argv[1]
image = Image.open(image_path)

# Perform OCR (Object Character Recognition) on the image
text = pytesseract.image_to_string(image)

# Print the extracted text
print(text)
