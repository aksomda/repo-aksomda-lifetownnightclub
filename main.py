from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship

# Configuration de la base de données SQLite
SQLALCHEMY_DATABASE_URL = "sqlite:///./gestion_bar.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ==========================================
# 1. MODÈLES SQLALCHEMY (Base de données)
# ==========================================

class BoissonModel(Base):
    __tablename__ = "boissons"
    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String, unique=True, index=True, nullable=False)
    categorie = Column(String, nullable=False)  # "biere" ou "sucrerie"
    quantite = Column(Integer, nullable=False, default=0)
    prix_unitaire = Column(Float, nullable=False, default=0.0)

class ServeurModel(Base):
    __tablename__ = "serveurs"
    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    telephone = Column(String, unique=True, nullable=False)
    statut = Column(String, default="actif") # actif, repos

class TableModel(Base):
    __tablename__ = "tables"
    id = Column(Integer, primary_key=True, index=True)
    numero = Column(Integer, unique=True, nullable=False)
    capacite = Column(Integer, nullable=False)
    statut = Column(String, default="libre") # libre, occupee

class CommandeModel(Base):
    __tablename__ = "commandes"
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=False)
    serveur_id = Column(Integer, ForeignKey("serveurs.id"), nullable=False)
    statut = Column(String, default="en_cours") # en_cours, payee, annulee
    montant_total = Column(Float, nullable=False, default=0.0)
    date_creation = Column(DateTime, default=datetime.utcnow)

    table = relationship("TableModel")
    serveur = relationship("ServeurModel")
    lignes = relationship("LigneCommandeModel", cascade="all, delete-orphan")

class LigneCommandeModel(Base):
    __tablename__ = "lignes_commande"
    id = Column(Integer, primary_key=True, index=True)
    commande_id = Column(Integer, ForeignKey("commandes.id"), nullable=False)
    boisson_id = Column(Integer, ForeignKey("boissons.id"), nullable=False)
    quantite = Column(Integer, nullable=False)
    prix_total = Column(Float, nullable=False)

    boisson = relationship("BoissonModel")

Base.metadata.create_all(bind=engine)

# ==========================================
# 2. SCHÉMAS PYDANTIC (Validation & Échanges)
# ==========================================

# Boissons
class BoissonBase(BaseModel):
    nom: str
    categorie: str
    quantite: int = Field(ge=0)
    prix_unitaire: float = Field(ge=0.0)

class BoissonResponse(BoissonBase):
    id: int
    class Config:
        from_attributes = True

class StockUpdate(BaseModel):
    quantite: int = Field(ge=0)

# Serveurs
class ServeurCreate(BaseModel):
    nom: str
    prenom: str
    telephone: str

class ServeurResponse(ServeurCreate):
    id: int
    statut: str
    class Config:
        from_attributes = True

# Tables
class TableCreate(BaseModel):
    numero: int
    capacite: int

class TableResponse(TableCreate):
    id: int
    statut: str
    class Config:
        from_attributes = True

# Commandes
class LigneCommandeCreate(BaseModel):
    boisson_id: int
    quantite: int = Field(gt=0)

class CommandeCreate(BaseModel):
    table_id: int
    serveur_id: int
    lignes: List[LigneCommandeCreate]

class LigneCommandeResponse(BaseModel):
    id: int
    boisson_id: int
    boisson_nom: str
    quantite: int
    prix_total: float
    class Config:
        from_attributes = True

class CommandeResponse(BaseModel):
    id: int
    table_id: int
    table_numero: int
    serveur_id: int
    serveur_nom: str
    statut: str
    montant_total: float
    date_creation: datetime
    lignes: List[LigneCommandeResponse]
    class Config:
        from_attributes = True

# ==========================================
# 3. INITIALISATION APPLICATION & CORS
# ==========================================

app = FastAPI(title="API Gestion Bar & Stock", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Données initiales par défaut au premier démarrage
@app.on_event("startup")
def startup_event():
    db = SessionLocal()
    
    # Boissons par défaut
    initial_boissons = [
        {"nom": "Sobbra", "categorie": "biere", "quantite": 50, "prix_unitaire": 600.0},
        {"nom": "Brakina", "categorie": "biere", "quantite": 50, "prix_unitaire": 600.0},
        {"nom": "Beaufort", "categorie": "biere", "quantite": 40, "prix_unitaire": 700.0},
        {"nom": "Castel", "categorie": "biere", "quantite": 40, "prix_unitaire": 650.0},
        {"nom": "Guinness", "categorie": "biere", "quantite": 30, "prix_unitaire": 900.0},
        {"nom": "Doppel", "categorie": "biere", "quantite": 30, "prix_unitaire": 800.0},
        {"nom": "Brafort", "categorie": "biere", "quantite": 25, "prix_unitaire": 600.0},
        {"nom": "Brafaso", "categorie": "biere", "quantite": 25, "prix_unitaire": 550.0},
        {"nom": "Schweppes", "categorie": "sucrerie", "quantite": 60, "prix_unitaire": 500.0},
        {"nom": "Coca", "categorie": "sucrerie", "quantite": 80, "prix_unitaire": 500.0},
        {"nom": "Fanta", "categorie": "sucrerie", "quantite": 80, "prix_unitaire": 500.0},
        {"nom": "Chill Pomme", "categorie": "sucrerie", "quantite": 40, "prix_unitaire": 400.0},
        {"nom": "Chill Citron", "categorie": "sucrerie", "quantite": 40, "prix_unitaire": 400.0},
    ]
    for b in initial_boissons:
        if not db.query(BoissonModel).filter(BoissonModel.nom == b["nom"]).first():
            db.add(BoissonModel(**b))

    # Quelques tables par défaut
    for num in range(1, 6):
        if not db.query(TableModel).filter(TableModel.numero == num).first():
            db.add(TableModel(numero=num, capacite=4, statut="libre"))

    db.commit()
    db.close()

# ==========================================
# 4. ENDPOINTS : BOISSONS (STOCK)
# ==========================================

@app.get("/boissons", response_model=List[BoissonResponse])
def lister_boissons(db: Session = Depends(get_db)):
    return db.query(BoissonModel).all()

@app.patch("/boissons/{boisson_id}", response_model=BoissonResponse)
def modifier_stock_boisson(boisson_id: int, payload: StockUpdate, db: Session = Depends(get_db)):
    boisson = db.query(BoissonModel).filter(BoissonModel.id == boisson_id).first()
    if not boisson:
        raise HTTPException(status_code=404, detail="Boisson non trouvée")
    boisson.quantite = payload.quantite
    db.commit()
    db.refresh(boisson)
    return boisson

# ==========================================
# 5. ENDPOINTS : SERVEURS / SERVEUSES
# ==========================================

@app.get("/serveurs", response_model=List[ServeurResponse])
def lister_serveurs(db: Session = Depends(get_db)):
    return db.query(ServeurModel).all()

@app.post("/serveurs", response_model=ServeurResponse, status_code=status.HTTP_201_CREATED)
def ajouter_serveur(payload: ServeurCreate, db: Session = Depends(get_db)):
    nouveau = ServeurModel(**payload.dict(), statut="actif")
    db.add(nouveau)
    db.commit()
    db.refresh(nouveau)
    return nouveau

# ==========================================
# 6. ENDPOINTS : TABLES
# ==========================================

@app.get("/tables", response_model=List[TableResponse])
def lister_tables(db: Session = Depends(get_db)):
    return db.query(TableModel).all()

@app.post("/tables", response_model=TableResponse, status_code=status.HTTP_201_CREATED)
def ajouter_table(payload: TableCreate, db: Session = Depends(get_db)):
    existante = db.query(TableModel).filter(TableModel.numero == payload.numero).first()
    if existante:
        raise HTTPException(status_code=400, detail="Ce numéro de table existe déjà.")
    table = TableModel(**payload.dict(), statut="libre")
    db.add(table)
    db.commit()
    db.refresh(table)
    return table

# ==========================================
# 7. ENDPOINTS : COMMANDES
# ==========================================

@app.get("/commandes", response_model=List[CommandeResponse])
def lister_commandes(db: Session = Depends(get_db)):
    commandes = db.query(CommandeModel).all()
    resultat = []
    for c in commandes:
        lignes_resp = [
            LigneCommandeResponse(
                id=l.id,
                boisson_id=l.boisson_id,
                boisson_nom=l.boisson.nom,
                quantite=l.quantite,
                prix_total=l.prix_total
            ) for l in c.lignes
        ]
        resultat.append(CommandeResponse(
            id=c.id,
            table_id=c.table_id,
            table_numero=c.table.numero,
            serveur_id=c.serveur_id,
            serveur_nom=f"{c.serveur.prenom} {c.serveur.nom}",
            statut=c.statut,
            montant_total=c.montant_total,
            date_creation=c.date_creation,
            lignes=lignes_resp
        ))
    return resultat

@app.post("/commandes", response_model=CommandeResponse, status_code=status.HTTP_201_CREATED)
def creer_commande(payload: CommandeCreate, db: Session = Depends(get_db)):
    # Vérifier la table
    table = db.query(TableModel).filter(TableModel.id == payload.table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table introuvable.")
    
    # Vérifier le serveur
    serveur = db.query(ServeurModel).filter(ServeurModel.id == payload.serveur_id).first()
    if not serveur:
        raise HTTPException(status_code=404, detail="Serveur introuvable.")

    montant_total = 0.0
    nouvelle_commande = CommandeModel(table_id=table.id, serveur_id=serveur.id, statut="en_cours")
    db.add(nouvelle_commande)
    db.commit()
    db.refresh(nouvelle_commande)

    lignes_resp = []
    for ligne in payload.lignes:
        boisson = db.query(BoissonModel).filter(BoissonModel.id == ligne.boisson_id).first()
        if not boisson:
            raise HTTPException(status_code=404, detail=f"Boisson ID {ligne.boisson_id} introuvable.")
        
        # Vérification du stock
        if boisson.quantite < ligne.quantite:
            raise HTTPException(status_code=400, detail=Stock insuffisant pour {boisson.nom}. Stock actuel : {boisson.quantite})

        # Déduire du stock
        boisson.quantite -= ligne.quantite

        # Calculer le sous-total
        prix_ligne = boisson.prix_unitaire * ligne.quantite
        montant_total += prix_ligne

        # Enregistrer la ligne
        db_ligne = LigneCommandeModel(
            commande_id=nouvelle_commande.id,
            boisson_id=boisson.id,
            quantite=ligne.quantite,
            prix_total=prix_ligne
        )
        db.add(db_ligne)
        
        lignes_resp.append(LigneCommandeResponse(
            id=0, # temporaire avant commit des lignes
            boisson_id=boisson.id,
            boisson_nom=boisson.nom,
            quantite=ligne.quantite,
            prix_total=prix_ligne
        ))

    # Mettre à jour le montant total de la commande et le statut de la table
    nouvelle_commande.montant_total = montant_total
    table.statut = "occupee"
    db.commit()
    db.refresh(nouvelle_commande)

    return CommandeResponse(
        id=nouvelle_commande.id,
        table_id=table.id,
        table_numero=table.numero,
        serveur_id=serveur.id,
        serveur_nom=f"{serveur.prenom} {serveur.nom}",
        statut=nouvelle_commande.statut,
        montant_total=nouvelle_commande.montant_total,
        date_creation=nouvelle_commande.date_creation,
        lignes=lignes_resp
    )

@app.patch("/commandes/{commande_id}/cloturer", response_model=CommandeResponse)
def cloturer_commande(commande_id: int, db: Session = Depends(get_db)):
    commande = db.query(CommandeModel).filter(CommandeModel.id == commande_id).first()
    if not commande:
        raise HTTPException(status_code=404, detail="Commande introuvable.")
    
    commande.statut = "payee"
    
    # Libérer la table associée
    table = db.query(TableModel).filter(TableModel.id == commande.table_id).first()
    if table:
        table.statut = "libre"
        
    db.commit()
    db.refresh(commande)
    
    lignes_resp = [
        LigneCommandeResponse(
            id=l.id,
            boisson_id=l.boisson_id,
            boisson_nom=l.boisson.nom,
            quantite=l.quantite,
            prix_total=l.prix_total
        ) for l in commande.lignes
    ]
    
    return CommandeResponse(
        id=commande.id,
        table_id=commande.table_id,
        table_numero=commande.table.numero,
        serveur_id=commande.serveur_id,
        serveur_nom=f"{commande.serveur.prenom} {commande.serveur.nom}",
        statut=commande.statut,
        montant_total=commande.montant_total,
        date_creation=commande.date_creation,
        lignes=lignes_resp
    )