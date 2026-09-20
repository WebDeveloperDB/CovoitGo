import re

with open("TACHES_SPRINTS.md", "r", encoding="utf-8") as f:
    content = f.read()

# We want to replace each block of:
# - **Objectif** : ...
# - **Terminé quand** : ...
# - **Preuve** : ...
# with:
# - **Objectif** : ...
# - **Préconditions** : ... (generate based on context)
# - **Résultat attendu** : ... (was Terminé quand)
# - **Critères d'acceptation / Vérification** : ... (was Preuve)

# Since each task is unique, let's just generate a replacement dictionary or do it dynamically.

blocks = re.findall(r'(### T\d\.\d - .*?)(?=\n### T|\n## |\Z)', content, flags=re.DOTALL)

new_content = content[:content.find("### T2.0")]

def get_precondition(title):
    title = title.lower()
    if 'documenter les travaux' in title: return "Les ateliers de conception ont eu lieu."
    if 'finaliser le dépôt' in title: return "Le projet a été créé sur GitLab."
    if 'environnement flutter' in title: return "Un poste de travail avec accès administrateur et connexion internet."
    if 'environnement java' in title: return "Un poste de travail avec accès administrateur."
    if 'règles de style' in title: return "Le dépôt Git est initialisé."
    if 'squelette flutter' in title: return "L'environnement Flutter est installé (T2.2)."
    if 'squelette spring boot' in title: return "L'environnement Java est installé (T2.3)."
    if 'mongodb' in title: return "Docker ou un accès administrateur est disponible."
    
    if 'modèle de données' in title: return "Le cahier des charges et les cas d'utilisation sont validés."
    if 'diagramme de classes' in title: return "Le modèle de données MongoDB est esquissé."
    if 'docker compose local' in title: return "Les squelettes Spring Boot et MongoDB fonctionnent indépendamment."
    
    if 'contrat openapi' in title: return "Le diagramme de classes et les cas d'utilisation sont clairs."
    if 'authentification jwt' in title: return "Le contrat OpenAPI est validé et Spring Security est configuré."
    if 'protéger les routes' in title: return "L'authentification JWT est fonctionnelle."
    if 'création d\'un trajet' in title: return "La protection par rôle et la base MongoDB sont prêtes."
    
    if 'calcul haversine' in title: return "L'API backend est fonctionnelle."
    if 'règles de compatibilité' in title: return "Le calcul Haversine est testé et validé."
    if 'score et le classement' in title: return "Les règles de compatibilité sont en place."
    if 'recherche de trajets' in title: return "Le système de score et classement est opérationnel."
    
    if 'écran de connexion flutter' in title: return "Le squelette Flutter est prêt et l'API d'authentification fonctionne."
    if 'principale passager' in title: return "La recherche de trajets côté API est implémentée."
    if 'principale conducteur' in title: return "La création de trajets côté API est implémentée."
    if 'erreurs réseau' in title: return "L'application Flutter communique avec l'API."
    
    if 'envoi d\'une demande' in title: return "L'API gère la recherche et la publication de trajets."
    if 'acceptation et le refus' in title: return "L'envoi d'une demande est fonctionnel."
    if 'sqlite' in title: return "L'application mobile a une architecture de données claire."
    if 'synchronisation' in title: return "Le stockage local SQLite est opérationnel."
    
    if 'tests d\'intégration' in title: return "Toutes les routes API du MVP sont développées."
    if 'workflow passager' in title: return "L'application mobile et l'API sont connectées et stables."
    if 'workflow conducteur' in title: return "L'application mobile et l'API sont connectées et stables."
    if 'documentation technique' in title: return "Le développement du MVP est terminé."
    
    return "L'étape précédente est terminée."

for block in blocks:
    lines = block.strip().split('\n')
    title = lines[0]
    
    # Extract Objectif, Termine quand, Preuve
    obj = ""
    term = ""
    preuve = ""
    
    current = None
    for line in lines[1:]:
        if line.startswith('- **Objectif**'):
            current = 'obj'
            obj += line.replace('- **Objectif** :', '').strip() + " "
        elif line.startswith('- **Terminé quand**'):
            current = 'term'
            term += line.replace('- **Terminé quand** :', '').strip() + " "
        elif line.startswith('- **Preuve**'):
            current = 'preuve'
            preuve += line.replace('- **Preuve** :', '').strip() + " "
        else:
            if line.strip() == "": continue
            if current == 'obj': obj += line.strip() + " "
            elif current == 'term': term += line.strip() + " "
            elif current == 'preuve': preuve += line.strip() + " "
            
    precond = get_precondition(title)
    
    new_block = f"{title}\n\n"
    new_block += f"- **Préconditions** : {precond}\n"
    new_block += f"- **Objectif** : {obj.strip()}\n"
    new_block += f"- **Résultat attendu** : {term.strip()}\n"
    new_block += f"- **Manière de le vérifier (Critères d'acceptation)** : {preuve.strip()}\n\n"
    
    new_content += new_block

new_content += "## Ordre conseillé dans Jira\n\nCréer les tâches dans le Backlog, puis les déplacer dans les sprints dans cet ordre : Sprint 2, Sprint 3, Sprint 4, Sprint 5, Sprint 6, Sprint 7 et Sprint 8. Les tâches peuvent rester dans le Backlog tant que le sprint n'est pas confirmé. Il ne faut pas créer les tâches de notification d'arrivée, de paiement ou de navigation, car elles sont hors du MVP.\n"

with open("TACHES_SPRINTS.md", "w", encoding="utf-8") as f:
    f.write(new_content)
