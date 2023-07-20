*** Settings ***
Documentation       Order Robots using a CSV file, export every invoice as a PDF, zip all PDFs into one file.
Library    RPA.HTTP
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.PDF
Library    RPA.Excel.Application
Library    RPA.Tables
Library    OperatingSystem
Library    RPA.Archive

*** Variables ***
${Screenshots}=    ${OUTPUT_DIR}${/}Screenshots
${Receipts}=    ${OUTPUT_DIR}${/}Receipts
${Embedded_Receipts}=    ${OUTPUT_DIR}${/}Embedded_Receipts

*** Tasks ***
Order Robots using a CSV File, export every invoice as a PDF, zip all PDFs into one file.
    ${order_Data}=    Download CSV File
    Go to Website to Order Robots    
    Fill Order Form Using CSV    ${order_Data}
    Zip Embedded Receipts Folder
    [Teardown]    End it All

*** Keywords ***
Download CSV File
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${OUTPUT_DIR}${/}orders.csv    overwrite=${True}
    #IF    ${Response.status_code} != ${200}
    #    Log    "CSV can't be downloaded! Response Code: ${Response.status_code}"
    #END

    ${order_Data}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    header=${True}
    [Return]    ${order_Data}

Go to Website to Order Robots
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=${True}

Fill Order Form Using CSV
    [Arguments]    ${order_Data}
    FOR    ${row}    IN    @{order_Data}
        Fill Order Form    ${row}
        Take Screenshot of Robot preview    ${row}[Order number]
        Export Receipt as PDF    ${row}[Order number]
        Click Button    id:order-another
    END

Fill Order Form
   [Arguments]    ${row}
    Wait Until Element Is Visible    css:#root > div > div.modal > div > div
    Click Button    css:button[class="btn btn-dark"]
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview
    ${is_Receipt_There}=    Is Element Visible    id:receipt
    ${if_error_occurs}=    Is Element Visible    css:div.alert.alert-danger
    WHILE  ${is_Receipt_There} == ${False} or ${if_error_occurs} == ${True}
        Click Button     id:order
        ${is_Receipt_There}=    Is Element Visible    id:receipt
        ${if_error_occurs}=    Is Element Visible    css:div.alert.alert-danger
    END

Take Screenshot of Robot preview
    [Arguments]    ${Order_Number}
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(2)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(1)
    Screenshot    id:robot-preview-image    ${Screenshots}${/}robot-preview-${Order_Number}.png
        
Export Receipt as PDF
    [Arguments]    ${Order_Number}
    Wait Until Element Is Visible    id:receipt
    ${Receipt}=    Get Element Attribute    id:receipt   outerHTML
    Html To Pdf    ${Receipt}    ${Receipts}${/}Receipt-${Order_Number}.pdf
    Open Pdf    ${Receipts}${/}Receipt-${Order_Number}.pdf
    Add Watermark Image To Pdf    image_path=${Screenshots}${/}robot-preview-${Order_Number}.png    output_path=${Embedded_Receipts}${/}Receipt-${Order_Number}.pdf
    Close Pdf    ${Receipts}${/}Receipt-${Order_Number}.pdf

Zip Embedded Receipts Folder
    Archive Folder With Zip    ${Embedded_Receipts}    ${OUTPUT_DIR}${/}PDFs.zip

End it All
    Remove Directory    ${Embedded_Receipts}    recursive=${True}
    Remove Directory    ${Screenshots}    recursive=${True}
    Remove Directory    ${Receipts}    recursive=${True}