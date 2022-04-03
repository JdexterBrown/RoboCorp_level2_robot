*** Settings ***
Documentation     Orders Robot from RobotSpare Bin Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           Collections
Library           MyLibrary
Library           RPA.Browser.Selenium    auto_close=${TRUE}
Library           RPA.HTTP
Library           RPA.Excel.Application
Library           RPA.Tables
Library           Dialogs
Library           RPA.Desktop.Windows
Library           RPA.PDF
Library           Screenshot
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Resource          keywords.robot
Library           RPA.Robocorp.Vault



*** Variables ***
${bot_file_receipt_folder}=    ${OUTPUT_DIR}
#${pdf}=          ${OUTPUT_DIR}${/}{row}[Order number].pdf

*** Tasks ***
Order Robot from RobotSpare Bin Inc.
    open up webbrowswer to SpareBin Industries
    ${URL} =    URL Input Dialog from User
    ${orders} =    Download robot order Files    ${URL}
    FOR    ${row}    IN    @{orders}
        # ${pdf}=    Export As Pdf    ${row}[Order number]
        Close the annoying modal
        Wait Until Keyword Succeeds    10x    200ms    Fill in the form    ${row}
        Wait Until Keyword Succeeds    10x    200ms    Order robot
        #Wait Until Keyword Succeeds    10x    200ms    Order receipt visable
        Export reciept as PDF    ${row}
        Wait Until Keyword Succeeds    10x    100ms    ScreenShot of Robot    ${row}
        Embeed bot picture into pdf receipt    ${row}
        Wait Until Keyword Succeeds    10x    200ms    Order Another robot
    END
    Zip Robot receipts

*** Keywords ***
open up webbrowswer to SpareBin Industries
    ${secret}=    Get Secret    credentials   
    Open Available Browser    ${secret}[robot_url]
    #Open Available Browser    https://robotsparebinindustries.com/#/
    Click Link    Order your robot!

Download robot order Files
    [Arguments]    ${url}
    Download    ${url}    overwrite=True    
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders_table}=    Read table from CSV    orders.csv    header=true
    [Return]    ${orders_table}

Close the annoying modal
    #Click Element When Visible    css:.btn.btn-dark
    Click Button    css:.btn-dark

Fill in the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview
    #Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[2]/div[1]/button
    #Wait Until Element Is Visible    xpath://*{contains('Show model info')}

Order robot
    Click Button When Visible    //button[@class="btn btn-secondary"]
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Order Another Robot
    Click Button    id:order-another

Load data from CSV and fill out bot order form
    FOR    ${orders}    IN    @{orders}
        Log    ${orders}\[Order Number]
        #Fill in the form    orders
    END

Export reciept as PDF
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${bot_receipt}=    Get Element Attribute    id:receipt    outerHTML
    #${pdf}=    ${bot_file_receipt_folder}{/}{row}[Order number].pdf
    Html To Pdf    ${bot_receipt}    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    #[Return]    ${pdf}

ScreenShot of Robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    ${robot_image}=    Get Element Attribute    id:robot-preview-image    outerHTML
    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    filename=${OUTPUT_DIR}${/}${row}[Order number]_bot_Picture.png

Embeed bot picture into pdf receipt
    [Arguments]    ${row}
    #${Pdf}=    ${OUTPUT_DIR}${/}receipts${/}${row}[Order number].pdf
    #${image_of_bot_into_pdf}=    ${OUTPUT_DIR}${/}${row}[Order number]_bot_Picture.png
    #Open Pdf    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    Open PDF   ${OUTPUT_DIR}${/}${row}[Order number].pdf
    ${Files}=    Create List
    #...    ${bot_file_receipt_folder}${/}${row}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}${row}[Order number]_bot_Picture.png:align=center
    Add Files To Pdf    ${Files}    ${OUTPUT_DIR}${/}${row}[Order number].pdf    ${OUTPUT_DIR}${/}${row}[Order number]_bot_and_receipt.pdf
    #Close Pdf    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    Remove File    ${bot_file_receipt_folder}${/}${row}[Order number]_bot_Picture.png

Zip Robot receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    robot_reciepts.zip

URL Input Dialog from User
    Add heading    Which CSV?
    Add text input    url    label=The url to download the csv file:"https://robotsparebinindustries.com/orders.csv"    placeholder=https://robotsparebinindustries.com/orders.csv
    ${result}=    Run dialog
    [Return]    ${result.url}

Get and log the value of the vault secrets using the Get Secret 
    ${secret}=    Get Secret    credentials   
    Log    ${robot_url}