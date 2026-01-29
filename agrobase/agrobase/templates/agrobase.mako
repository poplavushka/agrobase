<%inherit file="app.mako"/>

<%block name="head">
    ${parent.head()}
    <style>
      /* Карта на главной странице */
      .home-language-map-wrapper {
        margin-top: 2em;
      }
      .home-language-map {
        height: 420px;
        border: 1px solid #ddd;
        border-radius: 4px;

        /* на всю ширину окна */
        width: 100vw;
        margin-left: calc(50% - 50vw);
        margin-right: calc(50% - 50vw);
      }
      .home-language-map-count {
        margin-top: 0.7em;
        font-weight: bold;
        font-size: 15px;
        color: #000;  /* чёрный текст */
      }

      /* Спрятать правое меню (Legal / Download / Contact), 
         т.к. мы добавили эти пункты в главное меню */
      .navbar .nav.pull-right {
        display: none;
      }
    /* values table on Language detail: make Example readable */
    .agro-col-example { white-space: normal !important; }
    .agro-example pre.agro-ex-line {
      white-space: pre-wrap;
      margin: 0 0 6px 0;
      padding: 0;
      border: 0;
      background: transparent;
      font-family: inherit;
      font-size: 14px;
      line-height: 1.35;
    }
    .agro-example .agro-translation {
      color: #444;
      margin-top: 4px;
    }
    .agro-col-source { white-space: normal !important; }
    .agro-col-example { white-space: normal !important; }
    .agro-example pre.agro-ex-line {
      white-space: pre-wrap;
      margin: 0 0 6px 0;
      padding: 0;
      border: 0;
      background: transparent;
      font-family: inherit;
      font-size: 14px;
      line-height: 1.35;
    }
    .agro-example .agro-translation { color: #444; margin-top: 4px; }
    .agro-col-source { white-space: normal !important; }

  .agro-lead {
    font-size: 18px;
    line-height: 1.6;
    margin-top: 6px;
  }
  .agro-text {
    font-size: 17px;
    line-height: 1.7;
  }


    </style>
</%block>

<%block name="header">
    ## Если понадобится логотип в шапке — раскомментируй:
    ## <a href="${request.route_url('dataset')}">
        ## <img src="${request.static_url('agrobase:static/header.gif')}"/>
    ## </a>
</%block>

${next.body()}


