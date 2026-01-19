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
    </style>
</%block>

<%block name="header">
    ## Если понадобится логотип в шапке — раскомментируй:
    ##<a href="${request.route_url('dataset')}">
    ##    <img src="${request.static_url('agrobase:static/header.gif')}"/>
    ##</a>
</%block>

${next.body()}
