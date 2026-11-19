enum TipoCombate {
  normal('normal'),
  fuego('fire'),
  agua('water'),
  electrico('electric'),
  planta('grass'),
  hielo('ice'),
  lucha('fighting'),
  veneno('poison'),
  tierra('ground'),
  volador('flying'),
  psiquico('psychic'),
  bicho('bug'),
  roca('rock'),
  fantasma('ghost'),
  dragon('dragon'),
  siniestro('dark'),
  acero('steel'),
  hada('fairy');

  const TipoCombate(this.idApi);

  final String idApi;

  factory TipoCombate.desdeApi(String id) {
    for (final tipo in values) {
      if (tipo.idApi == id) return tipo;
    }
    throw ArgumentError.value(id, 'id', 'Tipo de Pokémon no soportado');
  }
}
