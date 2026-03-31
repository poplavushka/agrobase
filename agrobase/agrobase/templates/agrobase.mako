<%inherit file="app.mako"/>

<%block name="head">
    ${parent.head()}
    <style>
      body,
      button,
      input,
      select,
      textarea,
      .btn,
      .navbar,
      .table,
      h1,
      h2,
      h3,
      h4,
      h5,
      h6 {
        font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
      }

      a,
      a:visited {
        color: #0492C2;
      }

      a:hover,
      a:focus {
        color: #03779e;
      }

      .btn-info.details,
      .btn-info.value-example {
        background: #4e8cd4;
        border: 1px solid #417fca;
        color: #fff;
        text-shadow: none;
        box-shadow: none;
      }

      .btn-info.details:hover,
      .btn-info.details:focus,
      .btn-info.value-example:hover,
      .btn-info.value-example:focus {
        background: #447fc3;
        border-color: #386fae;
        color: #fff;
      }

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

<%block name="footer_citation">
    ${request.dataset.formatted_name()}
</%block>

<%block name="footer">
    <div class="row-fluid" style="padding-top: 15px; border-top: 1px solid black;">
        <div class="span12" style="text-align: center;">
            ${request.dataset.formatted_name()}
            <br />
            is licensed under a
            <a rel="license" href="${request.dataset.license}">
                ${request.dataset.jsondata.get('license_name', request.dataset.license)}
            </a>.
            <br />
            <a class="clld-disclaimer" href="${request.route_url('legal')}">Disclaimer</a>
        </div>
    </div>
</%block>

${next.body()}

<script type="text/javascript">
  $(function () {
    $('a[href="https://docs.google.com/forms/d/e/1FAIpQLSftKiyTOWGrU0nksOCpqdvbv7SoW_11VQUe8OPMk-NVVEQpsw/viewform"]').attr({
      target: '_blank',
      rel: 'noopener noreferrer'
    });
  });
</script>
