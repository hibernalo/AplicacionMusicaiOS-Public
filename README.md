# Aplicacion Musica iOS

Aplicacion nativa de iOS para reproducir y gestionar tu coleccion de musica personal almacenada en Firebase. Desarrollada con SwiftUI.

## Vista Previa

<!-- INSERTAR CAPTURA: Vista principal de la aplicacion -->
![Vista Principal](screenshots/vista-principal.png)

---

## Caracteristicas Principales

### Reproductor de Audio
- Reproduccion de musica en streaming desde Firebase Storage
- Controles completos (play, pausa, anterior, siguiente)
- Barra de progreso interactiva
- Control de volumen
- Modos shuffle y repeat

<!-- INSERTAR CAPTURA: Reproductor o vista Now Playing -->
![Reproductor](screenshots/reproductor.png)

---

### Sistema de Filtros
- **Favoritas** - Canciones marcadas como liked
- **Recientes** - Ultimas canciones agregadas
- **Generos** - Filtra por genero musical
- **Artistas** - Explora por artista
- **Albums** - Navega por album
- **Anos** - Filtra por ano
- **Sources** - Filtra por fuente/origen
- **Playlists** - Listas de reproduccion personalizadas

<!-- INSERTAR CAPTURA: Filtros o navegacion -->
![Filtros](screenshots/filtros.png)

---

### Gestion de Playlists
- Crear playlists personalizadas
- Agregar y eliminar canciones
- Portadas personalizables

<!-- INSERTAR CAPTURA: Vista de playlists -->
![Playlists](screenshots/playlists.png)

---

### Busqueda
- Busqueda en tiempo real
- Busqueda contextual segun el filtro activo

<!-- INSERTAR CAPTURA: Barra de busqueda -->
![Busqueda](screenshots/busqueda.png)

---

### Modos de Vista
- Vista en grid con portadas
- Vista en lista compacta

<!-- INSERTAR CAPTURA: Diferentes modos de vista -->
![Vistas](screenshots/vistas.png)

---

## Tecnologias Utilizadas

| Componente | Tecnologia |
|------------|------------|
| Lenguaje | Swift 5+ |
| UI Framework | SwiftUI |
| Base de Datos | Firebase Firestore |
| Almacenamiento | Firebase Storage |
| Audio | AVFoundation |
| Arquitectura | MVVM |

---

## Estructura del Proyecto

```
AplicacionMusicaiOS/
├── AplicacionMusicaiOSApp.swift    # Punto de entrada
├── ContentView.swift                # Vista principal
├── GoogleService-Info.plist         # Credenciales Firebase (no incluido)
│
├── Models/
│   ├── Song.swift                   # Modelo de cancion
│   ├── Playlist.swift               # Modelo de playlist
│   ├── FilterMode.swift             # Modos de filtro
│   └── CountItem.swift              # Item con contador
│
├── Views/
│   ├── OnlineScreen.swift           # Pantalla principal
│   ├── NowPlayingView.swift         # Vista de reproduccion
│   ├── PlaybackBar.swift            # Barra de reproduccion
│   ├── FilterButtonsView.swift      # Botones de filtro
│   ├── FilterItemView.swift         # Item de filtro
│   ├── SongGridItem.swift           # Cancion en grid
│   ├── SongListItem.swift           # Cancion en lista
│   └── ImagePicker.swift            # Selector de imagen
│
├── ViewModels/
│   └── MusicViewModel.swift         # ViewModel principal
│
├── Services/
│   ├── AudioPlayer.swift            # Servicio de audio
│   └── OnlineRepository.swift       # Repositorio de datos
│
├── Extensions/
│   └── Color+Extensions.swift       # Extensiones de Color
│
└── Assets.xcassets/                 # Recursos graficos
```

---

## Instalacion

### Requisitos
- macOS con Xcode 15+
- iOS 17.0+
- Cuenta de Firebase con Firestore y Storage

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/AplicacionMusicaiOS.git
   cd AplicacionMusicaiOS
   ```

2. **Configurar Firebase**
   - Ve a [Firebase Console](https://console.firebase.google.com)
   - Crea o selecciona un proyecto
   - Agrega una app iOS
   - Descarga `GoogleService-Info.plist`
   - Colocalo en la raiz del proyecto

3. **Abrir en Xcode**
   ```bash
   open AplicacionMusicaiOS.xcodeproj
   ```

4. **Ejecutar**
   - Selecciona un simulador o dispositivo
   - Presiona Cmd + R

---

## Estructura de Datos en Firebase

### Coleccion `songs`
```swift
{
    title: "Nombre de la cancion",
    artist: "Artista",
    album: "Album",
    genre: "Genero",
    source: "Fuente",
    year: 2024,
    audioPath: "Audios/cancion.mp3",
    coverPath: "Covers/cancion.jpg",
    durationMs: 210000,
    liked: false
}
```

---

## Capturas Adicionales

### Vista Now Playing

<!-- INSERTAR CAPTURA: Pantalla completa de reproduccion -->
![Now Playing](screenshots/now-playing.png)

---

### Subida de Portadas

<!-- INSERTAR CAPTURA: Proceso de subir portada -->
![Subir Portada](screenshots/subir-portada.png)

---

### Vista en iPad (si aplica)

<!-- INSERTAR CAPTURA: Vista en iPad -->
![iPad](screenshots/ipad.png)

---

## Arquitectura

La aplicacion sigue el patron **MVVM** (Model-View-ViewModel):

- **Models**: Estructuras de datos (Song, Playlist, etc.)
- **Views**: Componentes de SwiftUI
- **ViewModels**: Logica de negocio y estado
- **Services**: Comunicacion con Firebase y reproduccion de audio

---

## Licencia

Proyecto de uso personal.

---

<!-- INSERTAR CAPTURA: Otra captura destacada -->
![Extra](screenshots/extra.png)
