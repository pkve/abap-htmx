CLASS ztf_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_http_extension.

  PROTECTED SECTION.

    TYPES t_sap_tables TYPE STANDARD TABLE OF dd02t WITH EMPTY KEY.

    DATA path TYPE string.
    DATA searched_string TYPE string.
    DATA page TYPE i.

    METHODS html_page RETURNING VALUE(html) TYPE string.
    METHODS html_shellbar RETURNING VALUE(html) TYPE string.
    METHODS html_searchbar RETURNING VALUE(html) TYPE string.
    METHODS html_table RETURNING VALUE(html) TYPE string.
    METHODS html_table_rows RETURNING VALUE(html) TYPE string.

    METHODS sap_table_getcount RETURNING VALUE(count) TYPE i.
    METHODS sap_table_getlist RETURNING VALUE(sap_tables) TYPE t_sap_tables.

  PRIVATE SECTION.

ENDCLASS.


CLASS ztf_handler IMPLEMENTATION.


  METHOD if_http_extension~handle_request.

    IF server->request->get_header_field(
         if_http_header_fields_sap=>request_method ) = `GET`.

      me->path = server->request->get_header_field(
                   if_http_header_fields_sap=>path_translated_expanded ).
      me->searched_string = escape( val = server->request->get_form_field( `q` )
                                    format = cl_abap_format=>e_html_text ).

      IF server->request->get_header_field( `hx-request` ) IS INITIAL.

        server->response->append_cdata( html_page( ) ).
        server->response->append_cdata( html_shellbar( ) ).
        server->response->append_cdata( html_searchbar( ) ).
        server->response->append_cdata( html_table( ) ).

      ELSE.

        CASE server->request->get_header_field( `app-action` ).

          WHEN `search`.
            server->response->append_cdata( html_table( ) ).

          WHEN `search_init`.
            CLEAR searched_string.
            server->response->append_cdata( html_searchbar( ) ).
            server->response->append_cdata( html_table( ) ).

          WHEN `scroll`.
            page = server->request->get_header_field( `app-page` ).
            server->response->append_cdata( html_table_rows( ) ).

        ENDCASE.

      ENDIF.

      server->response->set_status( code = 200
                                    reason = if_http_status=>reason_200 ).
      server->response->set_content_type( `text/html` ).

    ENDIF.

  ENDMETHOD.


  METHOD html_page.

    CONCATENATE `https://sap.github.io/fundamental-styles/`
                `theming-base-content/content/Base/baseLib/baseTheme/fonts`
                INTO DATA(fonts_url).

    CONCATENATE
    `<!DOCTYPE html>`
    `<html lang="en-US">`
      `<head>`
        `<meta charset="utf-8">`
        `<meta name="viewport" content="width=device-width, initial-scale=1">`
        `<title>` 'Table finder'(tfi) `</title>`
        `<link rel="icon" href="https://www.sap.com/favicon.ico">`
        `<link rel="stylesheet" href="https://unpkg.com/fundamental-styles`
                                     `@latest/dist/fundamental-styles.css">`
        `<style>`
          `@font-face { font-family: '72'; `
                       `src: url('` fonts_url `/72-Regular.woff') format('woff');`
                       `font-weight: normal; font-style: normal;}`
          `@font-face { font-family: '72'; `
                       `src: url('` fonts_url `/72-Bold.woff') format('woff');`
                       `font-weight: 700; font-style: normal;}`
          `@font-face { font-family: 'SAP-icons'; `
                       `src: url('` fonts_url `/SAP-icons.woff') format('woff');`
                       `font-weight: normal; font-style: normal;}`
        `</style>`
        `<script src="https://unpkg.com/htmx.org@latest/dist/htmx.js"></script>`
        `<meta name="htmx-config" content='{"defaultSwapStyle":"outerHTML"}'>`
      `</head>`
      `<body>` INTO html.

  ENDMETHOD.


  METHOD html_shellbar.

    CONCATENATE
    `<div style="height:45px">`
      `<div class="fd-shellbar">`
        `<div class="fd-shellbar__group fd-shellbar__group--product">`
          `<span class="fd-shellbar__logo">`
            `<img src="https://unpkg.com/fundamental-styles/dist/images/sap-logo@4x.png" `
                 `width="48" height="24" alt="logo">`
          `</span>`
          `<span class="fd-shellbar__title">` 'Table finder'(tfi) `</span>`
        `</div>`
      `</div>`
    `</div>` INTO html.

  ENDMETHOD.


  METHOD html_searchbar.

    CONCATENATE
    `<div id="searchbar" style="margin:0.5em; display:grid; place-items: center;" `
         `data-hx-swap-oob="true">`
      `<div id="search_input" class="fd-input-group" style="max-width: 300px;" `
            `data-hx-push-url="true" `
            `data-hx-target="#sap_tables">`
        `<input class="fd-input fd-input-group__input" `
               `type="text" placeholder="` 'Search'(sea) `" autofocus `
               `name="q" value="` searched_string `" `
               `data-hx-trigger="changed, keyup changed delay:250ms" `
               `data-hx-get="` path `" `
               `data-hx-headers='{"app-action": "search"}'>`
        `<span class="fd-input-group__addon fd-input-group__addon--button">`
          `<button class="fd-button fd-button--transparent" `
                  `aria-label="button-decline" `
                  `data-hx-get="` path `" `
                  `data-hx-headers='{"app-action": "search_init"}'>`
            `<i class="sap-icon--decline"></i>`
          `</button>`
        `</span>`
      `</div>`
    `</div>` INTO html.

  ENDMETHOD.


  METHOD html_table.

    DATA(table_count) = |{ sap_table_getcount( ) NUMBER = USER }|.
    DATA(table_rows) = html_table_rows( ).

    CONCATENATE
    `<table id="sap_tables" `
           `class="fd-table fd-table--responsive fd-table--no-horizontal-borders `
                  `fd-table--compact">`
      `<thead class="fd-table__header">`
        `<tr class="fd-table__row">`
          `<th class="fd-table__cell" scope="col">`
            'Table'(tab)
            `<span class="fd-info-label fd-info-label--numeric `
                         `fd-info-label--accent-color-6" style="margin:0.2rem">`
              `<span class="fd-info-label__text">` table_count `</span>`
            `</span>`
          `</th>`
          `<th class="fd-table__cell" scope="col">` 'Description'(des) `</th>`
        `</tr>`
      `</thead>`
      `<tbody class="fd-table__body">`
         table_rows
      `</tbody>`
    `</table>` INTO html.

  ENDMETHOD.


  METHOD html_table_rows.

    page = COND #( WHEN page IS INITIAL THEN 1 ELSE page ).

    DATA(sap_tables) = sap_table_getlist( ).

    IF lines( sap_tables ) > 0.

      DATA(next_page) = |{ page + 1 }|.

      CONCATENATE
      `<tr data-hx-trigger="revealed" `
          `data-hx-get="` path `" `
          `data-hx-vals='{"q": "` searched_string `"}' `
          `data-hx-headers='{"app-action": "scroll", "app-page": "` next_page `"}' `
          `data-hx-target="closest tbody" `
          `data-hx-swap="beforeend">`
        `<td colspan="2"></td>`
      `</tr>` INTO html.

      LOOP AT sap_tables INTO DATA(sap_table).

        CONCATENATE html
        `<tr class="fd-table__row fd-table__row--hoverable">`
          `<td class="fd-table__cell">` sap_table-tabname `</td>`
          `<td class="fd-table__cell">` sap_table-ddtext `</td>`
        `</tr>` INTO html.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD sap_table_getlist.

    DATA(search_name) = COND #( WHEN searched_string = to_upper( searched_string )
                                THEN searched_string && `%` ELSE `[]` ).
    DATA(search_desc) = COND #( WHEN searched_string <> to_upper( searched_string )
                                THEN `%` && searched_string && `%` ELSE `[]` ).
    DATA(offset) = 100 * ( page - 1 ).

    SELECT dd02l~tabname, ddtext FROM dd02l
      LEFT JOIN dd02t ON dd02t~tabname = dd02l~tabname AND dd02t~ddlanguage = @sy-langu
                     AND dd02t~as4local = dd02l~as4local AND dd02t~as4vers = dd02l~as4vers
     WHERE tabclass IN ( `TRANSP`, `CLUSTER`, `POOL` )
       AND ( dd02l~tabname LIKE @search_name OR ddtext LIKE @search_desc )
     ORDER BY dd02l~tabname
      INTO CORRESPONDING FIELDS OF TABLE @sap_tables
     UP TO 100 ROWS
    OFFSET @offset.

  ENDMETHOD.


  METHOD sap_table_getcount.

    DATA(search_name) = COND #( WHEN searched_string = to_upper( searched_string )
                                THEN searched_string && `%` ELSE `[]` ).
    DATA(search_desc) = COND #( WHEN searched_string <> to_upper( searched_string )
                                THEN `%` && searched_string && `%` ELSE `[]` ).

    SELECT COUNT( DISTINCT dd02l~tabname ) FROM dd02l
      LEFT JOIN dd02t ON dd02t~tabname = dd02l~tabname AND dd02t~ddlanguage = @sy-langu
                     AND dd02t~as4local = dd02l~as4local AND dd02t~as4vers = dd02l~as4vers
     WHERE tabclass IN ( `TRANSP`, `CLUSTER`, `POOL` )
       AND ( dd02l~tabname LIKE @search_name OR ddtext LIKE @search_desc )
      INTO @count.

  ENDMETHOD.


ENDCLASS.
