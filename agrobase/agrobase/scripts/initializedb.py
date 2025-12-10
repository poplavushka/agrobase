import csv
from pathlib import Path

from clld.cliutil import Data, bibtex2source
from clld.db.meta import DBSession
from clld.db.models import common
from clld.lib import bibtex

from agrobase import models

# Папка с нашими CSV и sources.bib
DATA_DIR = Path(__file__).parent.parent / "data"


def load_sources(data: Data):
    """
    Загрузить источники из sources.bib в common.Source.

    Используем clld.lib.bibtex + bibtex2source.
    """
    bib_path = DATA_DIR / "sources.bib"
    db = bibtex.Database.from_file(bib_path)

    for rec in db:
        # bibtex2source создаёт объект common.Source из записи BibTeX
        src = bibtex2source(rec)
        data.add(common.Source, src.id, _obj=src)

def load_languages(data: Data):
    """
    Загрузка языков из languages.csv в common.Language.
    glottocode и genetic кладём в jsondata.
    """
    path = DATA_DIR / "languages.csv"
    with path.open(encoding="utf-8") as fp:
        for row in csv.DictReader(fp):
            lang = data.add(
                common.Language,
                row["ID"],
                id=row["ID"],
                name=row["Name"],
                latitude=float(row["Latitude"]) if row["Latitude"] else None,
                longitude=float(row["Longitude"]) if row["Longitude"] else None,
            )
            jd = {}
            if row.get("Glottocode"):
                jd["glottocode"] = row["Glottocode"]
            if row.get("Genetic"):
                jd["genetic"] = row["Genetic"]
            if jd:
                lang.jsondata = jd

                
def load_parameters_and_codes(data: Data):
    # 1. Параметры
    ppath = DATA_DIR / "parameters.csv"
    with ppath.open(encoding="utf-8") as fp:
        for row in csv.DictReader(fp):
            p = data.add(
                common.Parameter,
                row["ID"],
                id=row["ID"],
                name=row["Name"],
                description=row.get("Description") or None,
            )
            group = row.get("Group") or ""
            if group:
                p.jsondata["group"] = group
            parent = row.get("Parent") or ""
            if parent:
                p.jsondata["parent"] = parent

    # 2. Коды (DomainElement)
    cpath = DATA_DIR / "codes.csv"
    with cpath.open(encoding="utf-8") as fp:
        for row in csv.DictReader(fp):
            param = data["Parameter"][row["Parameter_ID"]]

            raw_id = row["ID"]                  # напр. "alignment.neutral"
            safe_id = raw_id.replace(".", "_")  # "alignment_neutral"

            # Игнорируем, что лежит в Name, и стандартизируем:
            # берём всё после первой точки, если она есть.
            if "." in raw_id:
                label = raw_id.split(".", 1)[1].strip()
            else:
                # fallback: либо Name, либо сам raw_id
                label = (row.get("Name") or raw_id).strip()

            data.add(
                common.DomainElement,
                safe_id,
                id=safe_id,
                name=label,
                parameter=param,
            )



def load_values(data: Data, contribution: common.Contribution):
    path = DATA_DIR / "values.csv"
    with path.open(encoding="utf-8") as fp:
        reader = csv.DictReader(fp)
        for row in reader:
            lang = data["Language"][row["Language_ID"]]
            param = data["Parameter"][row["Parameter_ID"]]

            raw_code_id = row.get("Code_ID") or ""        # из CSV, с точками
            safe_code_id = raw_code_id.replace(".", "_")  # без точек

            de = None
            if safe_code_id:
                de = data["DomainElement"].get(safe_code_id)

            vs_key = f"{param.id}-{lang.id}"
            if vs_key in data["ValueSet"]:
                vs = data["ValueSet"][vs_key]
            else:
                vs = data.add(
                    common.ValueSet,
                    vs_key,
                    id=vs_key,
                    language=lang,
                    parameter=param,
                    contribution=contribution,
                )
                

            value_id = f"{vs_key}-{safe_code_id or 'x'}"
            kwargs = dict(
                id=value_id,
                valueset=vs,
            )
            if de is not None:
                kwargs["domainelement"] = de
                kwargs["name"] = de.name
            else:
                kwargs["name"] = raw_code_id or ""

            comment = row.get("Comment")
            if comment:
                kwargs["description"] = comment

            data.add(common.Value, value_id, **kwargs)

            raw_src = (row.get("Source_ID") or "").replace(";", ",")
            source_ids = [
                s.strip() for s in raw_src.split(",") if s.strip()
            ]
            for sid in source_ids:
                try:
                    src = data["Source"][sid]
                except KeyError:
                    # если в CSV опечатка в ключе, просто пропускаем
                    continue
                # создаём ссылку ValueSet ↔ Source
                DBSession.add(
                    common.ValueSetReference(
                        source=src,
                        valueset=vs,
                    )
                )


def load_examples(data: Data):
    """
    Загрузка примеров из examples.csv в common.Sentence + линк к параметрам.
    """
    path = DATA_DIR / "examples.csv"
    if not path.exists():
        return

    with path.open(encoding="utf-8") as fp:
        reader = csv.DictReader(fp)
        for row in reader:
            lang = data["Language"][row["Language_ID"]]

            primary = row.get("Primary_Text") or ""
            gloss = row.get("Gloss") or ""
            translation = row.get("Translation") or ""

            # В разных версиях clld поля у Sentence немного отличаются,
            # но обычно name/description/gloss работают.
            sent = data.add(
                common.Sentence,
                row["ID"],
                id=row["ID"],
                name=primary,           # основной текст
                gloss=gloss,            # глоссы строкой
                description=translation,
                language=lang,
            )
           
            # линкуем пример к параметрам через нашу таблицу SentenceParameter
            param_ids = [
                p.strip()
                for p in row.get("Parameter_IDs", "").split(",")
                if p.strip()
            ]
            for pid in param_ids:
                try:
                    param = data["Parameter"][pid]
                except KeyError:
                    continue
                DBSession.add(models.SentenceParameter(sentence=sent, parameter=param))
            raw_src = (row.get("Source_ID") or "").replace(";", ",")
            source_ids = [
                s.strip() for s in raw_src.split(",") if s.strip()
            ]
            for sid in source_ids:
                try:
                    src = data["Source"][sid]
                except KeyError:
                    continue
                DBSession.add(
                    common.SentenceReference(
                        source=src,
                        sentence=sent,
                    )
                )

def main(args):
    """
    Основная точка входа: вызывается `clld initdb development.ini`.
    """
    data = Data()

    # 1. Dataset 
    dataset = common.Dataset(
        id="agrobase",
        name="Agrobase: Agreement and Language Metadata",
        domain="localhost",
        publisher_name="",
        publisher_place="",
    )
    DBSession.add(dataset)

    # 2. Contribution 
    contrib = common.Contribution(
        id="agrobase-contrib",
        name="Agrobase initial contribution",
    )
    DBSession.add(contrib)

    # 3. Загружаем данные по шагам
    load_sources(data)
    load_languages(data)
    load_parameters_and_codes(data)
    load_values(data, contrib)
    load_examples(data)


def prime_cache(args):
    """
    Если когда-нибудь нужно будет денормализовать данные для быстрых запросов,
    делаем это здесь. Пока можно оставить заглушкой.
    """
    pass
