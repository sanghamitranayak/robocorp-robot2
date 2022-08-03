*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium  auto_close=${False}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets



*** Keywords ***
 Get the URL from vault and Open robot Order website
     ${url}=    Get Secret    credentials
     Log        ${url}
     Open Available Browser      ${url}[robotsparebin]

Get orders.csv URL from User
    Add heading    Orders.CSV URL
    Add Text Input    URL    url
    ${result} =  Run dialog
    [Return]    ${result.URL}

Download the csv file
        ${CSV_File_URL} =  Get orders.csv URL from User
        Download  ${CSV_File_URL}  overwrite=True
Get orders
        ${orders}=    Read table from CSV  orders.csv  header=True
        [Return]  ${orders}
Close the annoying modal
        Click Button    OK

Submit the order And Keep Checking Until Success
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion

Submit the order
        Wait Until Keyword Succeeds    10x    1s     Submit the order And Keep Checking Until Success

Go to order another robot
        Click Button    order-another

Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview

Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts   ${CURDIR}${/}output${/}receipt.zip


Store the receipt as a PDF file
        [Arguments]  ${order_number}
        Wait Until Element Is Visible    id:order-completion  1 min 15 s
        ${receipt_results_html}=    Get Element Attribute    id:order-completion    outerHTML
        Html To Pdf    ${receipt_results_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
        [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
Take a screenshot of the robot
        [Arguments]    ${order_number}
        Screenshot     id:robot-preview    ${CURDIR}${/}output${/}${order_number}.png
        [Return]       ${CURDIR}${/}output${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    #Close Pdf      ${pdf}

Fill the form
        [Arguments]  ${row}
        Select From List By Value    head    ${row}[Head]
        Select Radio Button    body    ${row}[Body]
        Input text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
        Input Text    address    ${row}[Address]