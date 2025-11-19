from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship

from clld.db.meta import Base
from clld.db.models import common


class SentenceParameter(Base):
    """
    Связка между примерами (Sentence) и параметрами (Parameter).
    """
    __tablename__ = 'sentenceparameter'

    pk = Column(Integer, primary_key=True)
    sentence_pk = Column(Integer, ForeignKey('sentence.pk'), nullable=False)
    parameter_pk = Column(Integer, ForeignKey('parameter.pk'), nullable=False)

    sentence = relationship(common.Sentence, backref='parameter_links')
    parameter = relationship(common.Parameter, backref='sentence_links')
