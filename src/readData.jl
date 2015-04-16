# functions to read data
# originally in functions.jl
# Claudia March 2015


# ----- read data --------

# function to write a csv table from the expCF of an
# array of quartets
# warning: does not check if the expCF have been calculated
function writeExpCF(quartets::Array{Quartet,1})
    df = DataFrames.DataFrame(t1="",t2="",t3="",t4="",CF1234=0.,CF1324=0.,CF1423=0.)
    for(q in quartets)
        length(q.taxon) == 4 || error("quartet $(q.number) does not have 4 taxa")
        length(q.qnet.expCF) == 3 || error("quartet $(q.number) does have qnet with 3 expCF")
        append!(df,DataFrames.DataFrame(t1=q.taxon[1],t2=q.taxon[2],t3=q.taxon[3],t4=q.taxon[4],CF1234=q.qnet.expCF[1],CF1324=q.qnet.expCF[2],CF1423=q.qnet.expCF[3]))
    end
    df = df[2:size(df,1),1:size(df,2)]
    return df
end

writeExpCF(d::DataCF) = writeExpCF(d.quartet)

# function to write a csv table from the obsCF of an
# array of quartets
function writeObsCF(quartets::Array{Quartet,1})
    df = DataFrames.DataFrame(t1="",t2="",t3="",t4="",CF1234=0.,CF1324=0.,CF1423=0.)
    for(q in quartets)
        length(q.taxon) == 4 || error("quartet $(q.number) does not have 4 taxa")
        length(q.obsCF) == 3 || error("quartet $(q.number) does have qnet with 3 expCF")
        append!(df,DataFrames.DataFrame(t1=q.taxon[1],t2=q.taxon[2],t3=q.taxon[3],t4=q.taxon[4],CF1234=q.obsCF[1],CF1324=q.obsCF[2],CF1423=q.obsCF[3]))
    end
    df = df[2:size(df,1),1:size(df,2)]
    return df
end

writeObsCF(d::DataCF) = writeObsCF(d.quartet)

# function that takes a dataframe and creates a DataCF object
function readTableCF(df::DataFrame)
    warn("assume the numbers for the taxon read from the observed CF table match the numbers given to the taxon when creating the object network")
    size(df,2) == 7 || error("Dataframe should have 7 columns: 4taxa, 3CF")
    quartets = Quartet[]
    for(i in 1:size(df,1))
        push!(quartets,Quartet(i,string(df[i,1]),string(df[i,2]),string(df[i,3]),string(df[i,4]),[df[i,5],df[i,6],df[i,7]]))
    end
    d = DataCF(quartets)
    println("DATA: data consists of $(d.numTrees) gene trees and $(d.numQuartets) quartets")
    return d
end

readTableCF(file::ASCIIString) = readTableCF(readtable(file))

# ---------------- read input gene trees and calculate obsCF ----------------------

# function to read a file and create one object per line read
# (each line starting with "(" will be considered a topology)
# the file can have extra lines that are ignored
# returns an array of HybridNetwork objects (that can be trees)
function readInputTrees(file::String)
    try
        s = open(file)
    catch
        error("Could not find or open $(file) file");
    end
    vnet = HybridNetwork[];
    s = open(file)
    for line in eachline(s)
        c = line[1]
        if(c == '(')
           net = readTopologyUpdate(line)
           push!(vnet,net)
        end
    end
    close(s)
    !isempty(vnet) || return nothing
    return vnet
end

# function to list all quartets for a set of taxa names
# return a text file with the list of quartets, one per line
function allQuartets(taxon::Union(Vector{ASCIIString},Vector{Int64}))
    quartets = combinations(taxon,4)
    f = open("allQuartets.txt","w")
    for q in quartets
        write(f,"$(q[1]),$(q[2]),$(q[3]),$(q[4])\n")
    end
    close(f)
end

# function to list all quartets for a set of taxa names
# return a text file with the list of quartets, one per line
# instead of taxon names, only needs numTaxa
function allQuartets(numTaxa::Int64)
    quartets = combinations(1:numTaxa,4)
    f = open("allQuartets.txt","w")
    for q in quartets
        write(f,"$(q[1]),$(q[2]),$(q[3]),$(q[4])\n")
    end
    close(f)
end

# function to list num randomly selected quartets for a set of taxa names
# return a text file with the list of quartets, one per line
# input: file with the list of all quartets
function randQuartets(allQ::ASCIIString,num::Int64)
    try
        f = open(allQ)
    catch
        error("could not open file $(allQ)")
    end
    f = open(allQ)
    lines = readlines(f)
    n = length(lines)
    num <= n || error("you cannot choose a sample of $(num) quartets when there are $(n) in total")
    indx = [rep(1,num),rep(0,n-num)]
    indx = indx[sortperm(randn(n))]
    out = open("rand$(num)Quartets.txt","w")
    for i in 1:n
        if(indx[i] == 1)
            write(out,"$(lines[i])")
        end
    end
    close(out)
    close(f)
end

# function to list num randomly selected quartets for a set of taxa names
# return a text file with the list of quartets, one per line
# no input file with all quartets because it will create it
function randQuartets(numTaxa::Int64,num::Int64)
    allQuartets(numTaxa)
    f = open("allQuartets.txt")
    lines = readlines(f)
    n = length(lines)
    num <= n || error("you cannot choose a sample of $(num) quartets when there are $(n) in total")
    indx = [rep(1,num),rep(0,n-num)]
    indx = indx[sortperm(randn(n))]
    out = open("rand$(num)Quartets.txt","w")
    for i in 1:n
        if(indx[i] == 1)
            write(out,"$(lines[i])")
        end
    end
    close(out)
    close(f)
end

# function to list num randomly selected quartets for a set of taxa names
# return a text file with the list of quartets, one per line
# no input file with all quartets because it will create it
function randQuartets(taxon::Union(Vector{ASCIIString},Vector{Int64}),num::Int64)
    allQuartets(taxon)
    f = open("allQuartets.txt")
    lines = readlines(f)
    n = length(lines)
    num <= n || error("you cannot choose a sample of $(num) quartets when there are $(n) in total")
    indx = [rep(1,num),rep(0,n-num)]
    indx = indx[sortperm(randn(n))]
    out = open("rand$(num)Quartets.txt","w")
    for i in 1:n
        if(indx[i] == 1)
            write(out,"$(lines[i])")
        end
    end
    close(out)
    close(f)
end


# function to read list of quartets from a file
# and create Quartet type objects
function readListQuartets(file::ASCIIString)
    try
        f = open(file)
    catch
        error("could not open file $(file)")
    end
    f = open(file)
    quartets = Quartet[];
    i = 1
    for line in eachline(f)
        l = split(line,",")
        length(l) == 4 || error("quartet with $(length(l)) elements, should be 4: $(line)")
        push!(quartets,Quartet(i,string(l[1]),string(l[2]),string(l[3]),chomp(string(l[4])),[1.0,0.0,0.0]))
        i += 1
    end
    return quartets
end


# function to check if taxa in quartet is in tree t
function sameTaxa(q::Quartet, t::HybridNetwork)
    for name in q.taxon
        in(name,t.names) || return false
    end
    return true
end

# function to extract the union of taxa of list of gene trees
function unionTaxa(trees::Vector{HybridNetwork})
    taxa = trees[1].names
    for t in trees
        taxa = union(taxa,t.names)
    end
    return taxa
end

# function to extract the union of taxa of list of quartets
function unionTaxa(quartets::Vector{Quartet})
    taxa = quartets[1].taxon
    for q in quartets
        taxa = union(taxa,q.taxon)
    end
    return taxa
end

unionTaxaTree(file::ASCIIString) = unionTaxa(readInputTrees(file))


# function to calculate the obsCF from a file with a set of gene trees
# returns a DataCF object and write a csv table with the obsCF
function calculateObsCFAll!(quartets::Vector{Quartet}, trees::Vector{HybridNetwork})
    println("DATA: calculating obsCF from set of gene trees and list of quartets")
    for q in quartets
        suma = 0
        sum12 = 0
        sum13 = 0
        sum14 = 0
        for t in trees
            isTree(t) || error("gene tree found in file that is a network $(writeTopology(t))")
            if(sameTaxa(q,t))
                suma +=1
                qnet = extractQuartet!(t,q)
                identifyQuartet!(qnet)
                internalLength!(qnet)
                updateSplit!(qnet)
                for(i in 2:4)
                    size(qnet.leaf,1) == 4 || error("strange quartet with $(size(qnet.leaf,1)) leaves instead of 4")
                    tx1,tx2 = whichLeaves(qnet,q.taxon[1],q.taxon[i], qnet.leaf[1], qnet.leaf[2], qnet.leaf[3], qnet.leaf[4]) # index of leaf in qnet.leaf
                    if(qnet.split[tx1] == qnet.split[tx2])
                        #eval(parse(string("sum1",i,"+=1"))) # sum1i += 1
                        if(i == 2)
                            sum12 += 1
                        elseif(i == 3)
                            sum13 += 1
                        else
                            sum14 += 1
                        end
                        break
                    end
                end
            end
        end
        q.obsCF = [sum12/suma, sum13/suma, sum14/suma]
        q.numGT = suma
    end
    d = DataCF(quartets,trees)
    return d
end

# function to read input list of gene trees/quartets and calculates obsCF
# as opposed to readTableCF that read the table of obsCF directly
# input: treefile (with gene trees), quartetfile (with list of quartets),
# whichQ (:add/:rand to decide if all or random sample of quartets, default all)
# numQ: number of quartets in random sample
# writetab = true to write the table of obsCF as file with name filename
# does it by default
function readInputData(treefile::ASCIIString, quartetfile::ASCIIString, whichQ::Symbol, numQ::Int64, writetab::Bool, filename::ASCIIString)
    println("DATA: reading input data for treefile $(treefile) and quartetfile $(quartetfile)")
    trees = readInputTrees(treefile)
    if(whichQ == :all)
        println("DATA: will use all quartets")
        quartets = readListQuartets(quartetfile)
    elseif(whichQ == :rand)
        println("DATA: will use a random sample of $(numQ) quartets written in file rand$(numQ)Quartets.txt")
        randQuartets(quartetfile,numQ)
        quartets = readListQuartets("rand$(numQ)Quartets.txt")
    else
        error("unknown symbol for whichQ $(whichQ), should be either all or rand")
    end
    d = calculateObsCFAll!(quartets,trees)
    if(writetab)
        println("DATA: printing table of obsCF in file $(filename)")
        df = writeObsCF(d)
        writetable(filename,df)
    end
    descData(d)
    return d
end

readInputData(treefile::ASCIIString, quartetfile::ASCIIString, whichQ::Symbol, numQ::Int64, writetab::Bool) = readInputData(treefile, quartetfile, whichQ, numQ, writetab, "tableCF.txt")
readInputData(treefile::ASCIIString, quartetfile::ASCIIString, whichQ::Symbol, numQ::Int64) = readInputData(treefile, quartetfile, whichQ, numQ, true, "tableCF.txt")
readInputData(treefile::ASCIIString, quartetfile::ASCIIString) = readInputData(treefile, quartetfile, :all, 1, true, "tableCF.txt")
readInputData(treefile::ASCIIString, quartetfile::ASCIIString, writetab::Bool, filename::ASCIIString) = readInputData(treefile, quartetfile, :all, 1, writetab, filename)

# function to read input list of gene trees, and not the list of quartets
# so it creates the list of quartets inside and calculates obsCF
# as opposed to readTableCF that read the table of obsCF directly
# input: treefile (with gene trees), whichQ (:add/:rand to decide if all or random sample of quartets, default all)
# numQ: number of quartets in random sample
# taxa: list of taxa, if not given, all taxa in gene trees used
# writetab = true to write the table of obsCF as file with name filename
# does it by default
function readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64, taxa::Union(Vector{ASCIIString}, Vector{Int64}), writetab::Bool, filename::ASCIIString)
    println("DATA: reading input data for treefile $(treefile) and no quartetfile given: will get quartets here")
    trees = readInputTrees(treefile)
    if(whichQ == :all)
        println("DATA: will use all quartets based on taxa $(taxa)")
        allQuartets(taxa)
        quartets = readListQuartets("allQuartets.txt")
    elseif(whichQ == :rand)
        println("DATA: will use random sample of $(numQ) quartets based on taxa $(taxa) written in file rand$(numQ)Quartets.txt")
        randQuartets(taxa,numQ)
        quartets = readListQuartets("rand$(numQ)Quartets.txt")
    else
        error("unknown symbol for whichQ $(whichQ), should be either all or rand")
    end
    d = calculateObsCFAll!(quartets,trees)
    if(writetab)
         println("DATA: printing table of obsCF in file $(filename)")
        df = writeObsCF(d)
        writetable(filename,df)
    end
    descData(d)
    return d
end

readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64, taxa::Union(Vector{ASCIIString}, Vector{Int64}), writetab::Bool) = readInputData(treefile, whichQ, numQ, taxa, writetab, "tableCF.txt")
readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64, taxa::Union(Vector{ASCIIString}, Vector{Int64})) = readInputData(treefile, whichQ, numQ, taxa, true, "tableCF.txt")
readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64, writetab::Bool, filename::ASCIIString) = readInputData(treefile, whichQ, numQ, unionTaxaTree(treefile), writetab, filename)
readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64, writetab::Bool) = readInputData(treefile, whichQ, numQ, unionTaxaTree(treefile), writetab, "tableCF.txt")
readInputData(treefile::ASCIIString, whichQ::Symbol, numQ::Int64) = readInputData(treefile, whichQ, numQ, unionTaxaTree(treefile), true, "tableCF.txt")
readInputData(treefile::ASCIIString) = readInputData(treefile, :all, 1, unionTaxaTree(treefile), true, "tableCF.txt")
readInputData(treefile::ASCIIString,taxa::Union(Vector{ASCIIString}, Vector{Int64})) = readInputData(treefile, :all, 1, taxa, true, "tableCF.txt")
readInputData(treefile::ASCIIString, filename::ASCIIString) = readInputData(treefile, :all, 1, unionTaxaTree(treefile), true, filename)

# ---------------------- descriptive stat for input data ----------------------------------

# function to check how taxa is represented in the input trees
function taxaTreesQuartets(trees::Vector{HybridNetwork}, quartets::Vector{Quartet},s::IO)
    taxaT = unionTaxa(trees)
    taxaQ = unionTaxa(quartets)
    dif = symdiff(taxaT,taxaQ)
    isempty(dif) ? write(s,"\nDATA: same taxa in gene trees and quartets: $(taxaT)\n") : write(s,"\nDATA: $(length(dif)) different taxa found in gene trees and quartets. \n Taxa $(intersect(taxaT,dif)) in trees, not in quartets; and taxa $(intersect(taxaQ,dif)) in quartets, not in trees\n")
    u = union(taxaT,taxaQ)
    for taxon in u
        numT = taxonTrees(taxon,trees)
        #numQ = taxonQuartets(taxon,quartets)
        write(s,"Taxon $(taxon) appears in $(numT) input trees ($(round(100*numT/length(trees),2)) %)\n")  #and $(numQ) quartets ($(round(100*numQ/length(quartets),2)) %)\n")
    end
end

taxaTreesQuartets(trees::Vector{HybridNetwork}, quartets::Vector{Quartet}) = taxaTreesQuartets(trees, quartets, STDOUT)

# function that counts the number of trees in which taxon appears
function taxonTrees(taxon::ASCIIString, trees::Vector{HybridNetwork})
    suma = 0
    for t in trees
        suma += in(taxon,t.names) ? 1 : 0
    end
    return suma
end

# function that counts the number of quartets in which taxon appears
function taxonQuartets(taxon::ASCIIString, quartets::Vector{Quartet})
    suma = 0
    for q in quartets
        suma += in(taxon,q.taxon) ? 1 : 0
    end
    return suma
end


# function to create descriptive stat from input data, will save in stream s
# which can be a file or STDOUT
# default: file "descData.txt"
function descData(d::DataCF, s::IO)
    write(s,"DATA: data consists of $(d.numTrees) gene trees and $(d.numQuartets) quartets")
    taxaTreesQuartets(d.tree,d.quartet,s)
    write(s,"----------------------------\n\n")
    for q in d.quartet
        write(s,"Quartet $(q.number) obsCF constructed with $(q.numGT) gene trees ($(round(q.numGT/d.numTrees*100,2))%)\n")
    end
    write(s,"----------------------------\n\n")

end

function descData(d::DataCF, filename::ASCIIString)
    println("DATA: printing descriptive stat of input data in file $(filename)")
    s = open(filename, "w")
    descData(d,s)
    close(s)
end

descData(d::DataCF) = descData(d, "descData.txt")

# ------------------ read starting tree from astral and put branch lengths ------------------------------

# function to read the starting topology (can be tree/network)
# if updateBL=true, updates the branch lengths with the obsCF in d
# by default, updateBL=true
function readStartTop(file::String,d::DataCF,updateBL::Bool)
    net = readTopology(file)
    if(updateBL)
        updateBL!(net,d)
    end
    return net
end

readStartTop(file::String,d::DataCF) = readStartTop(file,d,true)
readStartTop(file::String) = readStartTop(file,DataCF(),false)

# function to update branch lengths with obsCF from d
# if net is a tree, it is based on Cecile code: ch4-species-tree-units.r
function updateBL!(net::HybridNetwork,d::DataCF)
    if(isTree(net))
        ff
    else
        #fixit: what to do here?
    end
end
