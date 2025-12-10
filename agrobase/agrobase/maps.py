# agrobase/maps.py

from clld.web.maps import SelectedLanguagesMap


def includeme(config):
    # Регистрируем карту "feature_combination" как SelectedLanguagesMap:
    # она умеет рисовать произвольный список языков,
    # который мы передаём через req.get_map(..., languages=languages)
    config.register_map('feature_combination', SelectedLanguagesMap)
