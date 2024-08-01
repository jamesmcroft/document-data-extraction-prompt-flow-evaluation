# Create a function that can be called by a Bash command to convert a specified PDF file to a collection of images per page in a specified directory.

import os
import sys
from pdf2image import convert_from_path

def pdf_to_image(pdf_path: str, output_dir: str):
    """Loads a PDF file, converts it to a collection of images per page, and saves the images to a specified directory.
    
    :param pdf_path: The path to the PDF file to convert to images.
    :param output_dir: The directory to save the images to.
    """
    
    # Create the output directory if it does not exist, otherwise remove all files in the output directory
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    else:
        for file in os.listdir(output_dir):
            file_path = os.path.join(output_dir, file)
            os.remove(file_path)
        
    pages = convert_from_path(pdf_path, fmt='jpeg')
    
    pdf_file_name = os.path.basename(pdf_path)
    
    for i, page in enumerate(pages):
        page_ref = i + 1
        
        # page_ref in the image path should be padded with zeros to maintain the order of the pages, e.g., 001, 002, 003, ..., 010, 011, ...
        
        image_path = os.path.join(output_dir, f'{pdf_file_name}.Page-{str(page_ref).zfill(3)}.jpg')
        page.save(image_path, 'JPEG')
        
pdf_to_image(sys.argv[1], sys.argv[2])