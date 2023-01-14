module TTNKit
    using SparseArrays
    using TensorKit
    using ITensors
    using Distributions: Multinomial
    using Parameters: @with_kw
    using MPSKit: MPOHamiltonian, DenseMPO, _embedders, SparseMPO, PeriodicArray
    using MPSKitModels: LocalOperator
    using KrylovKit

    struct NotImplemented <: Exception
        fn::Symbol
        type_name
    end
    Base.showerror(io::IO, e::NotImplemented) = print(io, e.fn, " not implemented for this type: ", e.type_name)

    struct DimensionsException{D} <: Exception
        dims::NTuple{D,Int}
    end
    function Base.showerror(io::IO, e::DimensionsException{D}) where D
        n_sites = prod(e.dims)
        s_err = "Number of Sites $(n_sites) is not compatible with a binary network of dimension $D"
        s_err *= " with n layers requireing number_of_sites = 2^(n_$(D))"
        print(io, s_err)
    end

    struct NotSupportedException <: Exception
        msg::AbstractString
    end
    Base.showerror(io::IO, e::NotSupportedException) = print(io, "Functionality is not supported: "*e.msg)

    struct QuantumNumberMissmatch <: Exception end
    Base.showerror(io::IO, ::QuantumNumberMissmatch) = print(io, "Quantum number combination not allowed.")

    struct IndexMissmatchException <: Exception 
        idx::Index
        desc::String
    end
    Base.showerror(io::IO, e::IndexMissmatchException) = print(io, "Index $(e.idx) not fullfill requirements: $(e.desc)") 


    # imports
    import Base: eachindex, size, ==, getindex, setindex, iterate, length, show, copy, eltype
    import TensorKit: sectortype, spacetype
    import ITensors: state, op, space, siteinds
    using ITensors: dim as dim_it
    using TensorKit: dim as dim_tk

    dim(ind::I) where{I} = I <: Index ? dim_it(ind) : dim_tk(ind) 

    include("./backends/backends.jl")

    # contract_tensor ncon wrapper
    #include("./contract_tensors.jl")

    # nodes
    #export TrivialNode, HardCoreBosonNode, Node
    include("./Node/AbstractNode.jl")
    include("./Node/Node.jl")
    include("./Node/ITensorNode.jl")
    include("./Node/HardCoreBosonNode.jl")
    include("./Node/SoftCoreBosonNode.jl")
    include("./Node/SpinHalfNode.jl")


    # lattice class
    include("./Lattice/AbstractLattice.jl")
    include("./Lattice/SimpleLattice.jl")

    # including the Network classes
    include("./Network/AbstractNetwork.jl")
    include("./Network/BinaryNetwork.jl")

    include("./TreeTensorNetwork/TreeTensorNetwork.jl")
    #= Currently deactivating all class objects, starting implementing ITensor support
    export AbstractLattice, Chain, Rectangle, Square


    
    export BinaryNetwork, BinaryChainNetwork, BinaryRectangularNetwork

    
    export TreeTensorNetwork, RandomTreeTensorNetwork, ProductTreeTensorNetwork
    
    include("./TreeTensorNetwork/algorithms/inner.jl")

    # load the definition of special operator types for dispatching measuring functions
    include("./TPO/AbstractTensorDefinitions.jl")
    include("./TreeTensorNetwork/algorithms/expect.jl")

    include("./TreeTensorNetwork/algorithms/correlation.jl")
    

    #============================= TENSOR PRODUCT OPERATORS =========================#
    # abstract TPO
    include("./TPO/AbstractTPO.jl")
    # MPO class
    include("./TPO/MPO.jl")
    include("./TPO/ProjTPO.jl")

    # model implementations
    include("./TPO/Models/TransverseFieldIsing.jl")
    include("./TPO/Models/TrivialModel.jl")


    # dmrg
    include("./algorithms/SweepHandler/AbstractSweepHandler.jl")
    include("./algorithms/SweepHandler/SimpleSweepHandler.jl")
    include("./algorithms/SweepHandler/TDVPSweepHandler.jl")
    include("./algorithms/sweeps.jl")

    =#


    #=


    # TPO TODO:Tests

    include("./TPO/TPOSum/Interactions.jl")
    include("./TPO/TPOSum/TPOSum.jl")
    =#

end # module
