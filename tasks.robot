*** Settings ***
Documentation       Template robot main suite.

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${PDF_Path}         ${OUTPUT_DIR}${\}robot-${order}[Order number].pdf
${Retry}            1
${Retry_Limit}      3


*** Tasks ***
Order from Robot from RobotSpareBin Industries
    Open the intranet
    Download and read the Orders using CSV File
    [Teardown]    End sessions


*** Keywords ***
Download and read the Orders using CSV File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${Orders} =    Read table from CSV    orders.csv    header=True
    #${orders} =    get
    FOR    ${order}    IN    @{Orders}
        Fill the form and submit    ${order}
        #Log    ${order}[Head]
    END

Open the intranet
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Fill the form and submit
    [Arguments]    ${order}
    Select From List By Index    id=head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id=address    ${order}[Legs]
    Click Button    id=preview
    Click Button    id=order
    ${Status} =    Does Page Contain Element    id=order
    IF    ${Status}== True
        WHILE    ${Retry} < ${Retry_Limit}
            TRY
                Click Button    Order
                ${Status} =    Does Page Contain Element    order
                IF    ${Status}==False                    BREAK
            EXCEPT
                ${Retry}+1
            END
        END
    END

    ###### Extract the output table as PDF ######
    ${ElementID} =    Wait Until Keyword Succeeds    3x    0.5 sec    Get Element Attribute    id=receipt    outerHTML
    Html To Pdf    ${ElementID}    /tmp/sample.pdf

    ###### Take Screenshot ######
    Wait Until Page Contains Element    id=robot-preview-image
    # Sleep    30
    Screenshot    id=robot-preview-image    approved.png

    ###### Embed the Screenshots into PDF ######
    # ${receiptPDF} =    Open Pdf    ${OUTPUT_DIR}${\temp\}robot-${order}[Order number].pdf
    Add Watermark Image To PDF
    ...    image_path=approved.png
    ...    source_path=/tmp/sample.pdf
    ...    output_path=output/output-PDF/${order}[Order number].pdf
    #Close Pdf    ${receiptPDF}
    # ${robot_png} =    Create List
    #...    ${OUTPUT_DIR}{/} receipt${order}[Order number].PNG
    #...    ${OUTPUT_DIR}${/}robot${order}[Order number].pdf
    #Add Files To Pdf    ${robot_png}    ${OUTPUT_DIR}${/}${order}[Order number].pdf

    Click Element When Visible    id=order-another
    #Wait Until Page Contains Element    OK
    Wait Until Keyword Succeeds    3x    0.5 sec    Click Button    OK

End sessions
    # Close Browser
    Archive Folder With Zip    output/output-PDF    OrdersPDF.zip
