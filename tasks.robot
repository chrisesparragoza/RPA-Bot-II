*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             DateTime
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault

*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${zip_directory}=           ${OUTPUT_DIR}${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the Excel File
    Fill the form using the data from the Excel file
    

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    
Click Ok
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
Download the Excel File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
Get Orders
    ${read table} =     Read table from CSV    orders.csv
    RETURN    ${read table}

Enter Data
    [Arguments]    ${order}
    Select From List By Value    head         ${order}[Head]
    Select Radio Button    body     ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${order}[Legs] 
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[4]/input   ${order}[Address] 
    Click Button    Preview
    Wait Until Keyword Succeeds    2min    500ms    Submit Order
    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
    Return to order form
Fill the form using the data from the Excel file
    ${orders}=    Get orders
    FOR      ${row}     IN     @{orders} 
    Click Ok
        Enter Data    ${row}
    END
Submit Order
    Click Button    Order
    Page Should Contain Element    id:receipt

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${Order Number}
    ${recieptresults} =  Get Element Attribute    css:#receipt    outerHTML   
    Html To Pdf    ${recieptresults}    ${OUTPUT_DIR}/${Order Number}.pdf
    RETURN    ${OUTPUT_DIR}/${Order Number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order Number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/robopic${Order Number}.png
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Order Number}
    # Open PDF    ${OUTPUT_DIR}/${Order Number}.pdf
    @{pseudo_file_list}=    Create List
    ...    ${OUTPUT_DIR}/${Order Number}.pdf
    ...    ${OUTPUT_DIR}/robopic${Order Number}.png:align=center

    Add Files To PDF    ${pseudo_file_list}    ${OUTPUT_DIR}/${Order Number}.pdf    ${False}
    # Close Pdf    ${OUTPUT_DIR}/${Order Number}.pdf

Log out and close the browser
    Close Browser

Name and make the ZIP
    ${date}=    Get Current Date    exclude_millis=True
    ${name_of_zip}=    Get Value From User    Give the name for the zip of the orders:
    Log To Console    ${name_of_zip}_${date}
    Create the ZIP    ${name_of_zip}_${date}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${name_of_zip}    