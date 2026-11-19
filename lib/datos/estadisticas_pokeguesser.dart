class EstadisticasPokeGuesser {
  int partidasJugadas;
  int victorias;
  int derrotas;

  EstadisticasPokeGuesser({
    this.partidasJugadas = 0,
    this.victorias = 0,
    this.derrotas = 0,
  });

  void registrarVictoria() {
    partidasJugadas++;
    victorias++;
  }

  void registrarDerrota() {
    partidasJugadas++;
    derrotas++;
  }

  Map<String, dynamic> toJson() {
    return {
      'partidasJugadas': partidasJugadas,
      'victorias': victorias,
      'derrotas': derrotas,
    };
  }

  factory EstadisticasPokeGuesser.fromJson(Map<String, dynamic> json) {
    return EstadisticasPokeGuesser(
      partidasJugadas: json['partidasJugadas'] ?? 0,
      victorias: json['victorias'] ?? 0,
      derrotas: json['derrotas'] ?? 0,
    );
  }
}
