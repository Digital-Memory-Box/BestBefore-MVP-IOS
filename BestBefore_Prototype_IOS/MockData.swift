import Foundation

struct MockData {
  static let roamingRooms: [RoomObject] = [
    RoomObject(
      name: "Squad Goals",
      ownerEmail: "maya@example.com",
      description: "Best crew, best memories. Living proof that weekends are always better together. We spent the whole afternoon exploring the hidden alleyways of the city, finding beauty in the graffiti-covered walls and the quiet corners that most people just walk past. Every photo here represents a moment of pure connection, away from the digital noise, just being present in the architecture of our friendship. This collection documents our collective journey through the summer of '25, where the days were long, the music was loud, and the world felt like it belonged to us. We hope these memories inspire you to gather your own squad and make some history.",
      tags: ["friends", "party"]
    ),
    RoomObject(
      name: "Ocean Soul",
      ownerEmail: "liam@example.com",
      description: "A peaceful journey through the depths of the Pacific. The sound of the waves has always been my sanctuary, a rhythmic heartbeat that reminds me of how vast and mysterious the world truly is. In this space, I've curated a series of moments from the coastline of Big Sur, where the cliffs meet the horizon in a dramatic embrace of mist and stone. These are the textures of salt, the colors of the deep teal, and the feeling of absolute solitude that only the ocean can provide. It's a sanctuary for the restless mind, a place to dive deep into the blue and find the clarity that only the water can bring. Dive in and find your own center.",
      tags: ["nature", "ocean"],
      theme: "Ocean"
    ),
    RoomObject(
      name: "Sunset Dreams",
      ownerEmail: "maya@example.com",
      description: "Capturing the golden hour in every frame. There's a specific moment when the sun dips below the horizon, and for just a few seconds, the whole world turns into a canvas of copper and rose. This room is a tribute to those fleeting minutes. I've spent months chasing this light across different landscapes, from the high desert of Arizona to the rooftops of Berlin. Each image is a love letter to the dying light, a reminder that the end of something can be the most beautiful part of it. These are my sunset dreams, captured so they never truly fade into the night. Walk through the warmth and let the golden light wash over you.",
      tags: ["vibes", "golden"],
      theme: "Sunset"
    ),
    RoomObject(
      name: "Cyber City",
      ownerEmail: "neo@example.com",
      description: "Neon dreams and digital realities. Welcome to the grid. This space is an exploration of the intersection between human emotion and technological advancement. In the neon-soaked streets of Tokyo and the rain-slicked docks of Singapore, I found a specific kind of beauty—a high-tech, low-life aesthetic that defines our modern era. The glitch in the system, the flickering signage, the chrome reflections in the puddles... it's all part of the digital heartbeat of our civilization. This is a story of wires and pulses, of artificial lights and very real feelings. Plug in to the Cyber City and see what the future feels like today.",
      tags: ["tech", "neon"],
      theme: "Cyberpunk"
    )
  ]

  static let hallwayRooms: [RoomObject] = [
    RoomObject(name: "Squad Goals", ownerEmail: "maya@example.com", description: "Best crew, best memories. Living proof that weekend...", tags: ["friends", "party", "summer", "vibes"], backgroundMusic: "https://soundcloud.com/jergkoppf/alocasia-bambino", theme: "cyberpunk"),
    RoomObject(name: "Morning Ride", ownerEmail: "kaya@example.com", description: "Sunrise cycles through the coastal trail. Nothing beats the morning mist.", tags: ["fitness", "outdoor", "cycling", "sunrise"], backgroundMusic: "https://soundcloud.com/jergkoppf/jerg-koppf-tag-und-nacht", theme: "ocean"),
    RoomObject(name: "Art Studio", ownerEmail: "leo@example.com", description: "Exploring raw textures and abstract forms in the heart of the city.", tags: ["art", "abstract", "studio", "creative"], backgroundMusic: "https://soundcloud.com/jergkoppf/jerg-koppf-tu-ne-representes", theme: "sunset")
  ]

  static let artistRooms: [RoomObject] = [
    RoomObject(name: "Abstract Mind", ownerEmail: "artist1@example.com", description: "Digital artist focusing on surreal landscapes and vibrant color theory.", tags: ["digital", "surreal", "color"], theme: "cyberpunk"),
    RoomObject(name: "Nature's Lens", ownerEmail: "artist2@example.com", description: "Capturing the unspoken beauty of the wilderness through a vintage lens.", tags: ["photo", "nature", "vintage"], theme: "forest"),
    RoomObject(name: "Urban Echo", ownerEmail: "artist3@example.com", description: "Street photographer documenting the rhythmic pulse of metropolitan life.", tags: ["street", "vibe", "urban"], theme: "ocean")
  ]
}
