from copier import run_copy
import json
import sys

filename = sys.argv[1]
f = open(filename)
data = json.load(f)


for cluster in data["cluster_names"]["value"]:
    #create structure for clusters
    run_copy("../flux-templating", "../flux",data={"new_group": "false","new_cluster": "true","cluster_name": cluster})

for group in data["cluster_groups"]["value"]:
    #create structure for cluster groups
    run_copy("../flux-templating", "../flux",data={"new_group": "true","new_cluster": "false","cluster_group": group})