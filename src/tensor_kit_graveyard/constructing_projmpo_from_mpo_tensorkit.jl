#### TODO: Consider directly environments with only isometric tensors to the left/right? This would be the standart i guess..
function _construct_bottom_environments(ttn::TreeTensorNetwork{N,T}, tpo::MPOWrapper{L, M, TensorKitBackend}) where{N,L, M, T<:TensorMap}

    net = network(ttn)

    n_sites = number_of_sites(net)
    n_tensors = number_of_tensors(net) + n_sites

    # first two vectors are for layer and position within the layer respectivley, 
    # third one is for enumerating the bottom environments - one for each child leg

    bEnvironment = Vector{Vector{Vector{T}}}(undef, number_of_layers(net)) 
    bIndices = Vector{Vector{Vector{Vector{Int}}}}(undef, number_of_layers(net)) 

    ham = tpo.data
    # First layer

    bEnvironment[1] = map(eachindex(net,1)) do pp
        chdnds = child_nodes(net, (1,pp))
        map(1:number_of_child_nodes(net, (1,pp))) do nn
            ham[inverse_mapping(tpo.mapping)[chdnds[nn][2]]]
        end
    end
    # first layer
    virt_leg = inverse_mapping(tpo.mapping)
    bIndices[1] = map(eachindex(net,1)) do pp
        chdnds = child_nodes(net, (1,pp))
        map(1:number_of_child_nodes(net, (1,pp))) do nn
            chdid_virt = virt_leg[chdnds[nn][2]]
            int_leg = internal_index_of_legs(net, (1, pp))

            if isone(chdid_virt)
                return [int_leg[nn] + n_tensors, int_leg[nn], -chdid_virt]
            elseif chdid_virt == number_of_sites(net)
                return [-chdid_virt+1, int_leg[nn] + n_tensors, int_leg[nn]]
            else
                return [-chdid_virt+1, int_leg[nn] + n_tensors, int_leg[nn], -chdid_virt]
            end 
        end
    end

    for ll in Iterators.drop(eachlayer(net), 1)
        bEnvironment[ll] = Vector{Vector{T}}(undef, number_of_tensors(net, ll))
        bIndices[ll] = Vector{Vector{Vector{Int}}}(undef, number_of_tensors(net, ll))

        for pp in eachindex(net, ll)
            n_chds = number_of_child_nodes(net, (ll,pp))
            bEnvironment[ll][pp] = Vector{AbstractTensorMap}(undef, n_chds)
            bIndices[ll][pp] = Vector{Vector{Int}}(undef, n_chds)

            for chd in child_nodes(net, (ll,pp))
                chd_idx = index_of_child(net, chd)

                tensorListTTN = [ttn[chd], adjoint(ttn[chd])]
                tensorListBottom = map(child_nodes(net, chd)) do cc
                    bEnvironment[chd[1]][chd[2]][index_of_child(net, cc)]
                end
                int_legs = internal_index_of_legs(net, chd)
                indexListTTN = [int_legs, vcat(int_legs[end], int_legs[1:end-1]).+n_tensors]
                indexListBottom = map(child_nodes(net, chd)) do cc
                    bIndices[chd[1]][chd[2]][index_of_child(net, cc)]
                end
                bIndices[ll][pp][chd_idx], bEnvironment[ll][pp][chd_idx] = contract_tensors(
                                        vcat(tensorListTTN, tensorListBottom), vcat(indexListTTN, indexListBottom)
                                        )
            end
        end
    end
    return bIndices, bEnvironment
end

# make this more readable
function _construct_top_environments(ttn::TreeTensorNetwork{N,T}, bEnv::Vector{Vector{Vector{T}}}, bInd::Vector{Vector{Vector{Vector{Int64}}}}) where{N, T<:TensorMap}


    net = network(ttn)
    n_sites = number_of_sites(net)
    n_tensors = number_of_tensors(net) + n_sites

    # first two vectors are for layer and position within the layer respectivley
    tEnvironment = Vector{Vector{T}}(undef, number_of_layers(net))

    tIndices = Vector{Vector{Vector{Int}}}(undef, number_of_layers(net)) 
    tIndices[number_of_layers(net)] = Vector{Vector{Int}}(undef, number_of_tensors(net, 1))

    # top environment of the top node
    dm_final = domain(ttn[(number_of_layers(net), 1)])
    tEnvironment[number_of_layers(net)] = [TensorKit.permute(isomorphism(dm_final, dm_final),(1,2))]
    tIndices[number_of_layers(net)][1] = [n_tensors, 2*n_tensors] 

    for ll in Iterators.drop(Iterators.reverse(eachlayer(net)), 1)
        tEnvironment[ll] = Vector{T}(undef, number_of_tensors(net, ll))
        tIndices[ll] = Vector{Vector{Int}}(undef, number_of_tensors(net, ll))

        for pp in eachindex(net, ll)
            prnt_nd = parent_node(net, (ll, pp))
            idx_chd = index_of_child(net, (ll, pp))
            tensorListTTN = [ttn[prnt_nd], adjoint(ttn[prnt_nd]), tEnvironment[prnt_nd[1]][prnt_nd[2]]]
            tensorListBottom = map(deleteat!(collect(1:number_of_child_nodes(net, prnt_nd)), idx_chd)) do chd_nd
                bEnv[prnt_nd[1]][prnt_nd[2]][chd_nd]
            end
            int_legs = internal_index_of_legs(net, prnt_nd)
            indexListTTN = [int_legs, vcat(int_legs[end], int_legs[1:end-1]) .+ n_tensors, tIndices[prnt_nd[1]][prnt_nd[2]]]
            indexListBottom = map(deleteat!(collect(1:number_of_child_nodes(net, prnt_nd)), idx_chd)) do chd_nd
                    bInd[prnt_nd[1]][prnt_nd[2]][chd_nd]
            end
            tIndices[ll][pp], tEnvironment[ll][pp] = contract_tensors(vcat(tensorListTTN, tensorListBottom),
                                                                      vcat(indexListTTN, indexListBottom))
        end
    end
    return tIndices, tEnvironment
end