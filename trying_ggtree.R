tree1 <- ape::read.tree("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre"); 

tree2 <- phytools::read.newick("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre")


library(ggtree)
ggtree(tree1)
ggtree(tree1, layout="slanted") 
ggtree(tree1, layout="circular")
ggtree(tree1, layout="fan", open.angle=120)
ggtree(tree1, layout="equal_angle")
ggtree(tree1, layout="daylight")
ggtree(tree1, branch.length='none')
ggtree(tree1, branch.length='none', layout='circular')
ggtree(tree1, layout="daylight", branch.length = 'none')

ggtree(tree1, mrsd="2021-01-01")+ theme_tree2()

ggtree(tree1,  mrsd="2023-01-01")+ geom_tiplab()+ theme_tree2()

ggtree(tree1)+ geom_tiplab()
