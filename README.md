# GDC-GeneExpressionPreprocessing

This script performs the preprocessing of Gene expression data from the GDC portal. (https://portal.gdc.cancer.gov/repository)

It extracts the GDC downloaded files, parse them, and call the GDC API for metadata of each file, such as case_id and sample_id (using apiRequest.txt).
Please note that this script may take a while to run when having a high number of files due to the API requests.

Here is the pipeline:
1. Download from the GDC portal manifest files from a specific type of interest (e.g. all TCGA projects and FPKM files, or FPKM-UQ)

2. After downloading manifest file/s, use the GDC client to download the files:

-> open cmd

-> change dir to the gdc_client directory

-> gdc_client download -m ManifestName.txt 
(you can also specify a target folder)


3. If you used several manifest files, merge them to one and put all the downloaded files in one folder.

4. Update the script parameters: the path of the manifest, data folder, output folder and path of the API request file.

5. Run the script preprocessGDC.m
The script reads the manifest file, and extracts each file (gz file).
Then loads the extracted files, and creates a struct which contains the data from all files.
Then, additional metadata for each file is added by using file_id and API requests as appears in the file apiRequest.txt.

The api request retrieves also additional identifiers that you may also save in your struct by modifying the script.
The apiRequest.txt file contains a query that contains $$$ and will be replaced by the script to the relevant file_id.
