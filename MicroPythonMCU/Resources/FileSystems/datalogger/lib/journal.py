# Module de la flash (/lib est sur le chemin d'import, comme sur la carte) :
# ajoute des lignes a un fichier CSV, en ecrivant l'en-tete a la creation.
import os


class Journal:
    def __init__(self, chemin, entete):
        self.chemin = chemin
        dossier, nom = chemin.rsplit('/', 1)
        if nom not in os.listdir(dossier or '/'):
            with open(chemin, 'w') as f:
                f.write(entete + '\n')

    def ajoute(self, ligne):
        with open(self.chemin, 'a') as f:
            f.write(ligne + '\n')
