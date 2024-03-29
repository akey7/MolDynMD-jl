module MolDyn

export r_ab, stretch_energy, stretch_gradient, stretch_velocity_verlet

# Distance from atom a to b
function r_ab(a, b)
    sqrt(sum((a-b).^2))
end

# Stretch energy for a 1-2 bond
function stretch_energy(a, b, k_ab, r_ab_eq) 
    0.5*k_ab*(r_ab(a, b)-r_ab_eq)^2
end

# Kinetic energy for an atom
function kinetic_energy(vs::Array{Float64}, ms::Array{Float64}, timestep, atom)
    v = vs[timestep, atom, :]
    m = ms[atom]
    0.5 * m * sum(v.^2)
end

# Stretch energy gradient for a single 1-2 bond
function stretch_gradient(a, b, k_ab, r_ab_eq)
    du_drab = 0.5 * k_ab * (2*r_ab(a, b)-2*r_ab_eq)
    drab_dxa = (a[1]-b[1])/r_ab(a, b)
    drab_dya = (a[2]-b[2])/r_ab(a, b)
    drab_dza = (a[3]-b[3])/r_ab(a, b)

    [drab_dxa, drab_dya, drab_dza] * du_drab
end

# Propagate 1-2 bond stretch trajectories
function stretch_velocity_verlet(xs, vs, accels, tkes, tpes, one_two_bonds, one_two_bonds_kab, one_two_bonds_req, ms, dt, num_steps)
    for time_i in 1:num_steps-1
        for bond_i in [1 2]
            k_ab = one_two_bonds_kab[bond_i]
            r_eq = one_two_bonds_req[bond_i]
            atom_a = one_two_bonds[bond_i, 1]
            atom_b = one_two_bonds[bond_i, 2]
            xs[time_i+1, atom_a, :] = xs[time_i, atom_a, :] + vs[time_i, atom_a, :] * dt + accels[time_i, atom_a, :] * dt^2
            v_mid = vs[time_i, atom_a, :] + 0.5 * accels[time_i, atom_a, :] * dt
            accels[time_i+1, atom_a, :] = -stretch_gradient(xs[time_i, atom_a, :], xs[time_i, atom_b, :], k_ab, r_eq) / ms[atom_a]  # Should this be reduced mass???
            vs[time_i+1, atom_a, :] = v_mid + 0.5 * accels[time_i+1, atom_a, :] * dt
        end

        tkes[time_i] = total_kinetic_energy(vs, ms, time_i)
        tpes[time_i] = total_stretch_energy(xs, one_two_bonds, one_two_bonds_kab, one_two_bonds_req, time_i)
    end

    tkes[num_steps] = total_kinetic_energy(vs, ms, num_steps)
    tpes[num_steps] = total_stretch_energy(xs, one_two_bonds, one_two_bonds_kab, one_two_bonds_req, num_steps)

    return nothing
end

# Determine the total kinetic energy of the system
function total_kinetic_energy(vs::Array{Float64}, ms::Array{Float64}, timestep::Int)
    sum([kinetic_energy(vs, ms, timestep, atom) for atom in eachindex(ms)])
end

# Determine total stretch energy of the system.
function total_stretch_energy(xs::Array{Float64}, one_two_bonds::Array{Int}, one_two_bonds_kab::Array{Float64}, one_two_bonds_req::Array{Float64}, timestep::Int)
    stretch_energies = zeros(Float64, length(one_two_bonds_kab))
    
    for i in eachindex(one_two_bonds_kab)
        atom_a = one_two_bonds[i, 1]
        atom_b = one_two_bonds[i, 2]
        k_ab = one_two_bonds_kab[i]
        r_eq = one_two_bonds_req[i]
        pos_a = xs[timestep, atom_a, 1:3]
        pos_b = xs[timestep, atom_b, 1:3]
        stretch_energies[i] = stretch_energy(pos_a, pos_b, k_ab, r_eq)
    end

    # Divide by 2.0 to prevent double counting the 1-2 bonds
    sum(stretch_energies) / 2.0
end

end
