<%inherit file="../home_comp.mako"/>

<%def name="sidebar()">
    ## Пустой сайдбар — правая колонка будет пустой,
    ## всё главное — в центральной части страницы.
</%def>

<h2>Welcome to AGRobase</h2>

<p class="lead">
    A database of Agreement Features
    Explore agreement features via Agreement table. If you have any suggestions,
  please write us via the Feedback button.
</p>

<div class="home-navigation" style="margin-top: 1.5em; margin-bottom: 2em;">
  <a class="btn btn-large btn-primary"
     href="${request.route_url('agreement_table')}"
     style="margin-right: 0.5em;">
    Agreement table
  </a>

  <a class="btn btn-large btn-info"
     href="${request.route_url('feature_combinations')}"
     style="margin-right: 0.5em;">
    Combination of features
  </a>

  <a class="btn btn-large"
     href="${request.route_url('param_groups')}">
    Parameter groups
  </a>

<!-- ВРЕМЕННАЯ кнопка фидбека через e-mail -->
  <a class="btn btn-large btn-warning"
     href="https://docs.google.com/forms/d/e/1FAIpQLSftKiyTOWGrU0nksOCpqdvbv7SoW_11VQUe8OPMk-NVVEQpsw/viewform?usp=header">
    Feedback
  </a>
</div>


