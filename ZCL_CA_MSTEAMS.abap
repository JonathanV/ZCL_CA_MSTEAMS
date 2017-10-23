class ZCL_CA_MSTEAMS definition
  public
  create public .

public section.

  types:
* https://messagecardplayground.azurewebsites.net/
    begin of ty_actions,
           _type type string,
           name type string,
           target type string,
         end of ty_actions .
  types:
    tty_actions type table of ty_actions WITH EMPTY KEY .
  types:
    begin of ty_inputs,
           _type type string,
           id type string,
           isMultiline type string,
           title type string,
         end of ty_inputs .
  types:
    tty_inputs type table of ty_inputs WITH EMPTY KEY .
  types:
    begin of ty_potentialAction,
             _type type string,
             name type string,
             inputs type tty_inputs,
             actions type tty_actions,
         end of ty_potentialAction .
  types:
    tty_potentialAction type table of ty_potentialaction WITH EMPTY KEY .
  types:
    begin of ty_image,
           image type string,
           title type string,
         end of ty_image .
  types:
    tty_images type table of ty_image  WITH EMPTY KEY .
  types:
    begin of ty_facts,
           name type string,
           value type string,
         end of ty_facts .
  types:
    tty_facts TYPE TABLE OF ty_facts  WITH EMPTY KEY .
  types:
    begin of ty_sections,
               title type string,
               activityImage type string,
               activityTitle type string,
               activitySubtitle type string,
               activityText type string,
               heroImage type ty_Image,
               text type string,
               facts TYPE tty_facts,
               images TYPE tty_images,
               potentialAction TYPE tty_potentialAction,
         end of ty_sections .
  types:
    tty_sections type table of ty_sections  WITH EMPTY KEY .
  types:
    begin of ty_message_card,
               _type type string,
               _context type string,
               summary type string,
               title type string,
               text type string,
               themeColor type string,
               sections type tty_sections,
         end of ty_message_card .

  class-data CO_TIMEOUT type I value 3 ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      !URL type STRING
      !MESSAGE_CARD type TY_MESSAGE_CARD optional
      !JSON_PAYLOAD type STRING optional .
  methods POST .
  class-methods BUILD_PAYLOAD
    importing
      !MESSAGE_CARD type TY_MESSAGE_CARD
    returning
      value(PAYLOAD) type STRING .
  class-methods POST_TO_TEAMS
    importing
      !URL type STRING
      !PAYLOAD type STRING optional
      !MESSAGE_CARD type TY_MESSAGE_CARD optional
    returning
      value(HTTP_CODE) type I .
protected section.
private section.

  data PAYLOAD type STRING .
  data URL type STRING .
  data MESSAGE_CARD type TY_MESSAGE_CARD .
ENDCLASS.



CLASS ZCL_CA_MSTEAMS IMPLEMENTATION.


  method BUILD_PAYLOAD.

*    MESSAGECARD -> JSON
     CHECK MESSAGE_CARD is NOT INITIAL.
     TRY .
       DATA(writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
       CALL TRANSFORMATION id SOURCE PAYLOAD~ = MESSAGE_CARD
                              RESULT XML writer.
       data(json_xstring) = writer->get_output( ).
       data(conv) = cl_abap_conv_in_ce=>create( encoding = 'UTF-8' input = json_xstring ).
       call method conv->read importing data = payload.

*      current transformation will create an extra "PAYLOAD~" field, need to remove it
       payload = replace( val   = payload
                          sub   = `"PAYLOAD_--7E":{`
                          with  = ``
                          occ   =   0  ).
*      @variables not valid in abap, named _variables instead, need to fix that here.
       payload = replace( val   = payload
                          sub   = `"_`
                          with  = `"@`
                          occ   =   0  ).
       data(iLen) = strlen( payload ) - 1.
       payload = payload(iLen).

     CATCH cx_root.
     ENDTRY.

  endmethod.


  method CONSTRUCTOR.
    me->url = url.
    me->message_card = message_card.
    me->payload = json_payload.
  endmethod.


  method POST.

   CHECK me->URL is NOT INITIAL.
   if PAYLOAD is INITIAL.
      me->payload = build_payload( MESSAGE_CARD = me->MESSAGE_CARD ).
   endif.
   zcl_ca_msteams=>post_to_teams( url = me->url payload = me->payload ).
   clear: me->url, me->payload.

  endmethod.


  method POST_TO_TEAMS.

   data(json_payload) = COND STRING(
         when message_card is not INITIAL
              then build_payload( message_card = message_card )
              else payload ).

   check json_payload is not initial.
   http_code = -1. "default error

*  Create the Http Client
   data: ld_client type ref to if_http_client.
   cl_http_client=>create_by_url( exporting url = url
                                  importing client = ld_client ).

*  Prepare the Request
   data(ld_request) = ld_client->request.
   ld_client->request->set_method( if_http_request=>co_request_method_post ). "post
   ld_client->request->if_http_entity~set_header_field( name  = 'Content-Type'
                                                        value = 'application/json' ).
   ld_client->request->if_http_entity~set_cdata( data = json_payload ).

   ld_client->send(  
     exporting timeout = co_timeout
     exceptions http_communication_failure = 1
                http_invalid_state         = 2
                http_processing_failed     = 3
                http_invalid_timeout       = 4
                others                     = 5 ).
   if sy-subrc = 0.
     ld_client->receive( 
          exceptions http_communication_failure = 1
                     http_invalid_state         = 2
                     http_processing_failed     = 3
                     others                     = 4 ).
     if sy-subrc = 0.
       ld_client->response->get_status( IMPORTING code = http_code ).
       if http_code = 200.
          "all good
       else.
          "error : cl_demo_output=>display( 'HTTP STATUS Not ok;' && lv_http_status ).
       endif.
     else.
       "communication failure
     endif.
   endif.
   ld_client->close( ).

  endmethod.
ENDCLASS.
