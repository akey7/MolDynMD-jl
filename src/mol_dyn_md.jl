module MolDyn

# Export everything: Minimially it will all need testing.
export r_ab, u_stretch, stretch_gradient, stretch_velocity_verlet

# Distance from atom a to b
function r_ab(a, b)
    sqrt(sum((a-b).^2))
end

# Stretch energy for a 1-2 bond
function u_stretch(a::Matrix{Float64}, b::Matrix{Float64}, k_ab::Float64, r_ab_eq::Float64) 
    0.5*k_ab*(r_ab(a,b)-r_ab_eq)^2
end

# Stretch energy gradient for a single 1-2 bond
function stretch_gradient(a, b, k_ab, r_ab_eq)
    du_drab = k_ab*(r_ab(a, b)-r_ab_eq)
    drab_dxa = (a[1]-b[1])/r_ab(a, b)
    drab_dya = (a[2]-b[2])/r_ab(a, b)
    drab_dza = (a[3]-b[3])/r_ab(a, b)

    [drab_dxa, drab_dya, drab_dza] .* du_drab
end

# Propagate 1-2 bond stretch trajectories
# function stretch_velocity_verlet(qs, vs, accels, one_two_bonds, one_two_bonds_kab, one_two_bonds_req, ms, dt, num_steps)
#     for time_i in 2:num_steps
#         for bond_i in [1 2]
#             k_ab = one_two_bonds_kab[bond_i]
#             r_eq = one_two_bonds_req[bond_i]
#             a_i = one_two_bonds[bond_i, 1]
#             b_i = one_two_bonds[bond_i, 2]
#             qs[time_i, a_i, :] = qs[time_i-1, a_i, :] + vs[time_i-1, a_i, :].*dt + accels[time_i-1, a_i, :].*(dt^2).*0.5
#             accels[time_i, a_i, :] = -stretch_gradient(qs[time_i-1, a_i, :], qs[time_i-1, b_i, :], k_ab, r_eq) / ms[a_i]
#             vs[time_i, a_i, :] = vs[time_i-1, a_i, :] + (accels[time_i-1, a_i, :] + accels[time_i, a_i, :]) .* dt .* 0.5
#         end
#     end
# end

function stretch_velocity_verlet(xs, vs, accels, one_two_bonds, one_two_bonds_kab, one_two_bonds_req, ms, dt, num_steps)
    for time_i in 1:num_steps-1
        for bond_i in [1 2]
            k_ab = one_two_bonds_kab[bond_i]
            r_eq = one_two_bonds_req[bond_i]
            atom_a = one_two_bonds[bond_i, 1]
            atom_b = one_two_bonds[bond_i, 2]
            v_mid = vs[time_i, atom_a, :] + 0.5 * accels[time_i, atom_a, :] * dt
            xs[time_i+1, atom_a, :] = xs[time_i, atom_a, :] + v_mid * dt
            accels[time_i+1, atom_a, :] = -stretch_gradient(xs[time_i, atom_a, :], xs[time_i, atom_b, :], k_ab, r_eq) / ms[atom_a]  # Should this be reduced mass???
            vs[time_i+1, atom_a, :] = v_mid + 0.5 * accels[time_i+1, atom_a, :] * dt
        end
    end
end

end
