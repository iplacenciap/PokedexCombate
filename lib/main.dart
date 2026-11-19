import 'package:flutter/material.dart';
import "package:proyecto_pokedex/pantallas/main_layout.dart";
import "package:proyecto_pokedex/logica/coleccion_servicio.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ColeccionServicio.instancia.cargar();
  runApp(const Pokedex());
}

class Pokedex extends StatelessWidget {
  const Pokedex({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      home: const MainLayout(),
    );
  }
}