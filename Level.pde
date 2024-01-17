class Level {
  String levelName;
  int levelIndex;
  String dataPath;
  boolean completed = false;  // un livello si definisce completo se sono state raccolte tutte le monete e aperte tutte le casse
  int numberOfRooms;

  int damagePeaks;      // danno delle trappole
  
  // rooms
  int tileSize = 16;
  int cols, rows;
  int[][] map;
  ArrayList<Room> rooms;
  
  final int BACKGROUND_TILE_TYPE = 0;
  final int FLOOR_TILE_TYPE = 1;
  final int START_ROOM_TILE_TYPE = 2;
  final int STAIRS_TILE_TYPE = 3;
  final int WALL_PERIMETER_TILE_TYPE = 4;
  final int HALLWAY_TILE_TYPE = 5;
  final int CHEST_TILE_TYPE = 6;
  final int PEAKS_TILE_TYPE = 7;
  
  // probabilita di spawn delle trappole all'interno del livello
  static final double TRAP_SPAWN_PROBABILITY = 0.03;
  
  // vita dei nemici
  static final int ENEMY_HP = 30; 

  // attributi
  PImage startFloorImage;
  PImage floorImage; // Immagine per il pavimento
  // private PImage wallImage;  // Immagine per sfondo
  // pareti delle stanze
  PImage wallImageNorth;
  // private PImage wallImageNorthTop;
  //private PImage wallImageNorthBottom;
  //private PImage wallImageSouth;
  //private PImage wallImageEast;
  //private PImage wallImageWest;
  PImage hallwayImage;         // immagine per i corridoi
  PImage peaksTrapImage;
  PImage stairsNextFloorImage; // scale per accedere al livello successivo

  ArrayList<Coin> coins;      // contiene le monete presenti nel livello

  // chest che puoi trovare nel livello
  int spawnLevel = 2; // Livello di spawn
  ArrayList<Chest> treasures; // Memorizza le posizioni degli oggetti

  // nemici che puoi trovare nel livello
  ArrayList<Enemy> enemies; // Lista dei nemici
  
  ArrayList<Item> dropItems; // lista degli oggetti caduti a terra
  
  PVector finalRoomPosition;
  PVector nextLevelStartRoomPosition;

  int startRoomIndex;
  int endRoomIndex;

  Level(String levelName, int levelIndex, String dataPath, int numberOfRooms) {
    this.levelName = levelName;
    this.completed = false;
    this.levelIndex = levelIndex;
    this.dataPath = dataPath;
    this.numberOfRooms = numberOfRooms;
    this.damagePeaks = 5;
    //finalRoomPosition = new PVector(int(random(width)), int(random(height)));
    //nextLevelStartRoomPosition = new PVector(int(random(width)), int(random(height)));
  }
  
  void loadAssetsLevel() {
    println("carico gli assets del livello...");
    startFloorImage = currentZone.startFloorImage;
    floorImage = currentZone.floorImage;
    wallImageNorth = currentZone.wallImageNorth;
    hallwayImage = currentZone.hallwayImage;
    stairsNextFloorImage = currentZone.stairsNextFloorImage;
    peaksTrapImage = currentZone.peaksTrapImage;
    hallwayImage = currentZone.hallwayImage;
    stairsNextFloorImage = currentZone.stairsNextFloorImage;
  }

  void init() {
    // inizializzo il livello
    println("inizializzo il livello...");
    
    // logica per la creazione del livello (mappa del livello)
    cols = width / tileSize;
    rows = height / tileSize;

    map = new int[cols][rows];
    rooms = new ArrayList<Room>();
    
    loadAssetsLevel();
    
    // togliere di qua
    //startFloorImage = loadImage(dataPath + "startTile.png");
    //floorImage = loadImage(dataPath + "floorTile.png");
    //wallImageNorth = loadImage(dataPath + "northWallTop.png");
    //hallwayImage = loadImage(dataPath + "hallwayTile.png");
    //stairsNextFloorImage = loadImage(dataPath + "stairsNextFloor.png");
    //peaksTrapImage = loadImage("data/trap/peaks.png");

    //startFloorImage = loadImage(dataPath + "startTile.png");
    //floorImage = loadImage(dataPath + "floorTile.png");
    //// wallImage = loadImage(dataPath + "wallTile.png");

    //wallImageNorth = loadImage(dataPath + "northWallTop.png");
    //wallImageNorthTop = loadImage(dataPath + "northWallTop.png");
    //wallImageNorthBottom = loadImage(dataPath + "northWallBottom.png");

    //wallImageSouth = loadImage(dataPath + "southWall.png");
    //wallImageEast = loadImage(dataPath + "eastWall.png");
    //wallImageWest = loadImage(dataPath + "westWall.png");

    //hallwayImage = loadImage(dataPath + "hallwayTile.png");
    //stairsNextFloorImage = loadImage(dataPath + "stairsNextFloor.png");

    // Genera stanze
    generateRooms();

    // Collega le stanze con corridoi
    connectRooms();

    // da rimuovere
    //map[int(rooms.get(startRoomIndex).getPosition().x)][int(rooms.get(startRoomIndex).getPosition().y)] = 2; // Stanza iniziale
    map[int(rooms.get(endRoomIndex).roomPosition.x)][int(rooms.get(endRoomIndex).roomPosition.y)] = 3; // Stanza finale

    // inizializza l'array dei drop items 
    // inizialmente è vuoto
    dropItems = new ArrayList<>();
    
    // genera le chest 
    generateRandomChests();
    
    // aggiungi i nemici
    // da chiamare quando il giocatore entra nella stanza
    generateEnemies();

    // genera le monete
    generateRandomCoins();
  }

  PVector getStartPosition() {
    println("start position: " + rooms.get(startRoomIndex).roomPosition);
    return rooms.get(startRoomIndex).roomPosition;
  }

  PVector getEndRoomPosition() {
    return rooms.get(endRoomIndex).roomPosition;
  }

  // metodi per la generazione delle stanze
  private void generateRooms() {
    for (int i = 0; i < numberOfRooms; i++) {
      generateRandomRoom();
    }

    // stanza iniziale e finale scelte casualmente
    startRoomIndex = int(random(rooms.size()));
    
    do {
      endRoomIndex = int(random(rooms.size()));
    } while(endRoomIndex == startRoomIndex);
    
    
    rooms.get(startRoomIndex).startRoom = true;
    rooms.get(endRoomIndex).endRoom = true;
  }

  private void generateRandomRoom() {
    int roomWidth = int(random(8, 20));
    int roomHeight = int(random(8, 20));
    int roomX, roomY;

    boolean roomOverlap;
    do {
      roomX = int(random(1, cols - roomWidth - 1));
      roomY = int(random(1, rows - roomHeight - 1));
      roomOverlap = checkRoomOverlap(roomX, roomY, roomWidth, roomHeight);
    } while (roomOverlap);
    
    // crea nuova stanza e aggiungila alla lista delle stanze
    // mi salvo le coordinate del centro della stanza 
    PVector roomPosition = new PVector(roomX + roomWidth / 2, roomY + roomHeight / 2);
    Room room = new Room(roomWidth, roomHeight, roomPosition);
    rooms.add(room);
    
    // rooms.add(new Room(roomWidth, roomHeight, new PVector(roomX + roomWidth / 2, roomY + roomHeight / 2)));

    // Estrai i muri dell'immagine dei muri delle stanze
    for (int x = roomX; x < roomX + roomWidth; x++) {
      for (int y = roomY; y < roomY + roomHeight; y++) {
        if (x == roomX || x == roomX + roomWidth - 1 || y == roomY || y == roomY + roomHeight - 1) {
          // Questi sono i bordi della stanza, quindi imposta il tile come tileType 3
          map[x][y] = WALL_PERIMETER_TILE_TYPE; // Imposta il tile come muro del perimetro
        } else {
          map[x][y] = FLOOR_TILE_TYPE; // Imposta il tile come pavimento
          
          // spawn delle trappole all'interno delle stanze
          // da migliorare
          double trapSpawnProbability = TRAP_SPAWN_PROBABILITY;
          double randomValue = random(1);
  
          // Se il numero casuale è inferiore o uguale alla probabilità di spawn, aggiungi una trappola
          if (randomValue <= trapSpawnProbability) {
            // Imposta il tile come trappola
            map[x][y] = PEAKS_TILE_TYPE; 
          }
        }
      }
    }
  }

  private boolean checkRoomOverlap(int x, int y, int width, int height) {
    for (int i = x - 1; i < x + width + 1; i++) {
      for (int j = y - 1; j < y + height + 1; j++) {
        // Verifica se il tile è già occupato (1 rappresenta il pavimento)
        if (map[i][j] == 1 || map[i][j] == 4) {
          return true;
        }
      }
    }
    return false;
  }

  private void connectRooms() {
    for (int i = 0; i < rooms.size() - 1; i++) {
      PVector room1 = rooms.get(i).roomPosition.copy();
      PVector room2 = rooms.get(i + 1).roomPosition.copy();

      int x1 = int(room1.x);
      int y1 = int(room1.y);
      int x2 = int(room2.x);
      int y2 = int(room2.y);

      // Collega le stanze con un corridoio
      while (x1 != x2 || y1 != y2) {
        if (map[x1][y1] != 1) map[x1][y1] = 5; // Imposta il tile come spazio vuoto (corridoio)

        int choice = int(random(2));
        if (choice == 0) {
          x1 += (x1 < x2) ? 1 : ((x1 > x2) ? -1 : 0);
        } else {
          y1 += (y1 < y2) ? 1 : ((y1 > y2) ? -1 : 0);
        }
      }
    }
  }

  // generatore di monete casuale
  private void generateRandomCoins() {
    coins = new ArrayList<>();
    boolean positionOccupied;
    int totalCoins = 20; // Modifica il numero di monete da generare come preferisci

    for (int i = 0; i < totalCoins; i++) {
      int x, y;

      do {
        // Scegli una posizione casuale sulla mappa
        x = (int) random(cols);
        y = (int) random(rows);

        // Verifica se la posizione è già occupata da un muro, una parete, una cassa o un'altra moneta
        positionOccupied = (map[x][y] == 0 || map[x][y] == 4 || map[x][y] == 5 || map[x][y] == 6 || map[x][y] == 3);
      } while (positionOccupied);

      // Crea una moneta con un valore casuale (puoi personalizzare il valore come preferisci)
      int coinValue = (int) random(1, 10); // Esempio: valore casuale tra 1 e 10
      Coin coin = new Coin(coinValue);
      coin.sprite = coin_sprite;
      coin.spritePosition = new PVector(x, y);

      // Aggiungi la moneta alla lista delle monete
      coins.add(coin);
    }
  }

  // da sistemare ma decente
  private void generateRandomChests() {
    treasures = new ArrayList<Chest>();
    boolean positionOccupied;
    Chest chest;
    Room room;  
    float commonChestSpawnRate = 1.0; // Tasso di spawn per le casse comuni (90%)
    float spawnRadius = 2;    // raggio di spawn della chest rispetto al centro della stanza 

    for (int i = 0; i < spawnLevel; i++) {
      // stanza selezionata casualmente
      // e verifica se nella stanza sono gia presenti casse
      do{
        room = rooms.get((int) random(rooms.size()));
      } while(room.isChestPresent);
      
      room.isChestPresent = true;
      
      // offset rispetto al centro della stanza
      float offsetX = random(-spawnRadius, spawnRadius);
      float offsetY = random(-spawnRadius, spawnRadius);
    
      int x, y;

      // Genera un numero casuale tra 0 e 1 per determinare il tipo di cassa
      float chestType = random(1);

      // di base le casse sono chiuse e non sono rare
      // isOpen è impostato su false nel costruttore
      // isRare è impostato su false nel costruttore
      if (chestType < commonChestSpawnRate) {
        // Genera una cassa comune
        chest = new Chest("Cassa comune" + i);
        chest.sprite = chest_close_sprite;
        chest.setId(i);
        chest.setOpenWith(silver_key);              // Specifica l'oggetto chiave necessario
        // Imposta altri attributi della cassa comune
      } else {
        // Genera una cassa rara
        chest = new Chest("Cassa rara" + i);
        chest.sprite = special_chest_close_sprite;
        chest.setId(i);
        chest.setOpenWith(golden_key);              // Specifica l'oggetto chiave necessario
        chest.setIsRare(true);
      }

      do {
        // posizione casuale intorno al centro della stanza selezionata casualmente
        x = (int) (room.roomPosition.x + offsetX);
        y = (int) (room.roomPosition.y + offsetY);

        // Verifica se la posizione è già occupata da un muro, una parete o un'altra cassa
        positionOccupied = (map[x][y] == 0 || map[x][y] == 4 || map[x][y] == 5 || map[x][y] == 6 || map[x][y] == 3);
      } while (positionOccupied);

      // Aggiungi la cassa alla lista delle casse
      chest.spritePosition = new PVector(x, y);
      map[x][y] = CHEST_TILE_TYPE; // Imposta il tipo di tile corrispondente a una cassa
      
      treasures.add(chest);
    }
  }

  // spawner aggiornato
  // genera nemici in ogni stanza in maniera casuale
  private void generateEnemies() {
    enemies = new ArrayList<Enemy>();
    boolean positionOccupied;

    for (Room room : rooms) {
      PVector roomPosition = room.roomPosition.copy();
      int roomWidth = room.roomWidth;
      int roomHeight = room.roomHeight;

      // Genera un numero casuale di nemici in ogni stanza
      // AGGIUNGI LOGICA DI DIFFICOLTA
      int numEnemiesInRoom = floor(random(3, 5)); 

      for (int i = 0; i < numEnemiesInRoom; i++) {
        int x, y;

        // spawn causale dei nemici all'interno della mappa
        do {
          x = int(random(roomPosition.x - roomWidth / 2, roomPosition.x + roomWidth / 2));
          y = int(random(roomPosition.y - roomHeight / 2, roomPosition.y + roomHeight / 2));

          // Verifica se la posizione è già occupata da un muro o un altro oggetto
          positionOccupied = map[x][y] == 0 || map[x][y] == 4 || map[x][y] == 5 || map[x][y] == 3 || map[x][y] == 2 || map[x][y] == 6;
        } while (positionOccupied);
        
        ConcreteDamageHandler damageTileHandler = new ConcreteDamageHandler();

        // creazione dell'entita nemico
        Enemy enemy = new Enemy(ENEMY_HP, "rat", 5, damageTileHandler);
        enemy.sprite = rat_enemy_sprite;
        enemy.spritePosition = new PVector(x, y);

        // Aggiungi il nemico alla lista
        enemies.add(enemy);
      }
    }
  }

  // disegna solo cio che vede il giocatore
  void display() {
    // Calcola i limiti dello schermo visibile in termini di celle di mappa
    int startX = floor((camera.x / (tileSize * camera.zoom)));
    int startY = floor((camera.y / (tileSize * camera.zoom)));
    int endX = ceil((camera.x + gameScene.width) / (tileSize * camera.zoom));
    int endY = ceil((camera.y + gameScene.height) / (tileSize * camera.zoom));
  
    // Assicurati che i limiti siano all'interno dei limiti della mappa
    startX = constrain(startX, 0, cols - 1);
    startY = constrain(startY, 0, rows - 1);
    endX = constrain(endX, 0, cols);
    endY = constrain(endY, 0, rows);

    for (int x = startX; x < endX; x++) {
      for (int y = startY; y < endY; y++) {
        int tileType = map[x][y];
        
        float centerX = x * tileSize + tileSize / 2;
        float centerY = y * tileSize + tileSize / 2;

        switch(tileType) {
        case BACKGROUND_TILE_TYPE:
          // sfondo
          gameScene.rectMode(CENTER);
          gameScene.fill(0); // nero
          gameScene.noStroke();
          gameScene.rect(centerX, centerY, tileSize, tileSize);
          break;

        case FLOOR_TILE_TYPE:
          // pavimento
          
          // hitbox del pavimento
          //gameScene.rectMode(CENTER);
          //gameScene.noFill(); // Nessun riempimento
          //gameScene.stroke(0, 0, 255); // Colore del bordo bianco
          //gameScene.rect(centerX, centerY, tileSize, tileSize);
          
          //gameScene.stroke(60);
          //gameScene.point(centerX, centerY);
          
          gameScene.imageMode(CENTER);
          gameScene.image(floorImage, centerX, centerY, tileSize, tileSize);
          break;

        case START_ROOM_TILE_TYPE:
          // Imposta l'immagine per la stanza iniziale (nero)          
          gameScene.imageMode(CENTER);
          gameScene.image(startFloorImage, centerX, centerY, tileSize, tileSize);
          break;

        case STAIRS_TILE_TYPE:
          // scale per il piano successivo
          gameScene.imageMode(CENTER);
          gameScene.image(stairsNextFloorImage, centerX, centerY, tileSize, tileSize);
          break;

        case WALL_PERIMETER_TILE_TYPE:
          // muri perimetrali
          
          // hitbox dei muri perimetrali
          //gameScene.rectMode(CENTER);
          //gameScene.noFill(); // Nessun riempimento
          //gameScene.stroke(100, 34, 50); // Colore del bordo bianco
          //gameScene.rect(centerX, centerY, tileSize, tileSize);
          
          //gameScene.stroke(60);
          //gameScene.point(centerX, centerY);
          
          gameScene.imageMode(CENTER);
          gameScene.image(wallImageNorth, centerX, centerY, tileSize, tileSize);
          break;

        case HALLWAY_TILE_TYPE:
          // corridoio
          gameScene.imageMode(CENTER);
          gameScene.image(hallwayImage, centerX, centerY, tileSize, tileSize);
          break;

        case CHEST_TILE_TYPE:
          // ci sta tenerlo sono statiche le casse
          // tesori
          gameScene.imageMode(CENTER);
          gameScene.image(floorImage, centerX, centerY, tileSize, tileSize);
          break;
          
        case PEAKS_TILE_TYPE:
          // peaks trap
          gameScene.imageMode(CENTER);
          gameScene.image(peaksTrapImage, centerX, centerY, tileSize, tileSize);
          break;
        }
      }
    }
  }
  
  void displayRooms() {
    for(int i = 0; i < rooms.size(); i++) {
      gameScene.rectMode(CENTER);
      gameScene.fill(0); // nero
      gameScene.stroke(255, 0, 0);
      gameScene.rect(rooms.get(i).roomPosition.x, rooms.get(i).roomPosition.y, rooms.get(i).roomWidth, rooms.get(i).roomHeight);
      
      gameScene.fill(255, 0, 0);
      gameScene.stroke(255, 0, 0);
      gameScene.strokeWeight(1);
      gameScene.point(rooms.get(i).roomPosition.x, rooms.get(i).roomPosition.y);
    }
  }
  
  // verifica la collisione con le scale
  // collide con le scale
  
  // metodo per il rilevamento delle collisioni 
  // da sistemare
  boolean playerCollide(Player aPlayer) { 
    if(aPlayer.spritePosition.x * currentLevel.tileSize + (aPlayer.sprite.width / 2) >= (rooms.get(endRoomIndex).roomPosition.x * currentLevel.tileSize) - (tileSize / 2)  &&            // x1 + w1/2 > x2 - w2/2
        (aPlayer.spritePosition.x * currentLevel.tileSize) - (aPlayer.sprite.width / 2) <= rooms.get(endRoomIndex).roomPosition.x * currentLevel.tileSize + (tileSize / 2) &&            // x1 - w1/2 < x2 + w2/2
        aPlayer.spritePosition.y * currentLevel.tileSize + (aPlayer.sprite.height / 2) >= (rooms.get(endRoomIndex).roomPosition.y * currentLevel.tileSize) - (tileSize / 2) &&           // y1 + h1/2 > y2 - h2/2
        (aPlayer.spritePosition.y * currentLevel.tileSize) - (aPlayer.sprite.height / 2) <= rooms.get(endRoomIndex).roomPosition.y * currentLevel.tileSize + (tileSize/ 2)) {            // y1 - h1/2 < y2 + h2/2
          return true;
    }
    
    return false;
  }
}
