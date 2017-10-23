# ZCL_CA_MSTEAMS
SAP ABAP -> MS Team integration
POST ms-team message from SAP with ABAP (via webhook)

USAGE:
"-------------------------------------------
" ABAP 7.40 and+
"-------------------------------------------
"Simple post using json payload
"---------------------------------------
zcl_ca_msteams=>post_to_teams( EXPORTING url = webhook_url payload = '{"TITLE":"Title!","TEXT":"main!","themecolor":"6FA0ED"}' ).
"---------------------------------------

"---------------------------------------
"Simple post using message_card document
"---------------------------------------
zcl_ca_msteams=>post_to_teams( 	url = webhook_url
				message_card = value zcl_ca_msteams=>ty_message_card(
				title = 'Hi'
                                text = 'This is the main text'
                                themecolor = '6FA0ED'
                               )
                             ).


*---------------------------------------
*instance & more complex message
*---------------------------------------
data(message) = value zcl_ca_msteams=>ty_message_card(
                        title = 'Post Title'
                        text = 'This is the main text'
                        themecolor = '6FA0ED'
                        sections = VALUE zcl_ca_msteams=>tty_sections(
                          ( title = 'Section #1 main title'
                            text = 'section 1'
                            activityimage = 'http://logo.png'
                          )
                          ( title = 'Section #2 main title'
                            text = 'Voici donc le contenu de la section 2'
                            activityimage = 'https://goo.gl/99999999.png'
                            facts = VALUE zcl_ca_msteams=>tty_facts(
                                          ( name  = 'Fact#1' value = 'Fact are goods' )
                                          ( name  = 'Fact#2' value = 'More facts, better posts' )
                                          )
                            " potentialaction is not working as per their example.
                          )
                        )
                      ).

data(o_teams) = new zcl_ca_msteams( url = webhook_url
                                    message_card = message ).
o_teams->post( ).

*or

zcl_ca_msteams=>post_to_teams( url = webhook_url
                              message = value zcl_ca_msteams=>ty_message_card(
                                              title = 'Post Title'
                                              text = 'This is the main text'
                                              themecolor = '6FA0ED'
                                              sections = VALUE zcl_ca_msteams=>tty_sections(
                                              ( title = 'Section #1 main title'
                                                text = 'section 1'
                                                activityimage = 'http://logo.png'
                                              )
                                              ( title = 'Section #2 main title'
                                                text = 'Voici donc le contenu de la section 2'
                                                activityimage = 'https://goo.gl/99999999.png'
                                                facts = VALUE zcl_ca_msteams=>tty_facts(
                                                       ( name  = 'Fact#1' value = 'Fact are goods' )
                                                       ( name  = 'Fact#2' value = 'More facts, better posts' )
                                                       )
                                                " potentialaction is not working as per their example.
                                              )
                                      ) 
                             ).

*-------------------------------------------
*pre-740 abap way
*-------------------------------------------
DATA: lv_message type zcl_ca_msteams=>ty_message_card,
      lv_section type zcl_ca_msteams=>ty_sections,
      lt_section type zcl_ca_msteams=>tty_sections.

lv_section-title = 'Title section #1'.
lv_section-text  = 'section 1'.
lv_section-activityimage = 'https://logo.png'.
APPEND lv_section to lt_section.

lv_section-title = 'Title section #2'.
lv_section-text  = 'section 2'.
lv_section-activityimage = 'https://goo.gl/95651651651.png'.
APPEND lv_section to lt_section.

lv_message-text = 'This is the main text'.
lv_message-title = 'Title of the post'.
lv_message-themecolor = '6FA0ED'.

lv_message-sections = lt_section.
data(o_teams2) = new zcl_ca_msteams( url = webhook_url
                                    message_card = lv_message ).
o_teams2->post( ).
*-------------------------------------------


Reference:
https://docs.microsoft.com/en-us/outlook/actionable-messages/
https://docs.microsoft.com/en-us/outlook/actionable-messages/actionable-messages-via-connectors
