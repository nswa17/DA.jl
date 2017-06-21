module DATools

    type FixedSizeBinaryMaxHeap
        heap::Array{UInt16}
        ind::UInt16
        FixedSizeBinaryMaxHeap(m_max::Int) = new(Array(UInt16, m_max), 0)
    end

    function Base.length(bmh::FixedSizeBinaryMaxHeap)
        return bmh.ind
    end

    function Base.push!{T <: Integer}(bmh::FixedSizeBinaryMaxHeap, value::T)
        bmh.ind += 1
        bmh.heap[bmh.ind] = value
        reshape_up!(bmh)
    end

    function top(bmh::FixedSizeBinaryMaxHeap)
        if bmh.ind == 0
            return 0
        else
            return bmh.heap[1]
        end
    end

    function Base.pop!(bmh::FixedSizeBinaryMaxHeap)
        ret_val = bmh.heap[1]
        bmh.heap[1] = bmh.heap[bmh.ind]
        bmh.ind -= 1
        reshape_down!(bmh)
        return ret_val
    end

    function Base.getindex(bmh::FixedSizeBinaryMaxHeap, ind::Int)
        return bmh.heap[ind]
    end

    function reshape_down!(bmh::FixedSizeBinaryMaxHeap)
        current_ind = 1
        while true
            c1, c2 = current_ind * 2, current_ind * 2 + 1
            if c1 > bmh.ind
                break
            elseif c2 > bmh.ind
                c = c1
            else
                c = bmh.heap[c1] < bmh.heap[c2] ? c2 : c1
            end
            if bmh.heap[current_ind] < bmh.heap[c]
                bmh.heap[c], bmh.heap[current_ind] = bmh.heap[current_ind], bmh.heap[c]
                current_ind = c
            else
                break
            end
        end
    end

    function reshape_up!(bmh::FixedSizeBinaryMaxHeap)
        current_ind = bmh.ind
        while true
            par = current_ind >> 1
            if par == 0 || bmh.heap[current_ind] <= bmh.heap[par]
                break
            else
                bmh.heap[current_ind], bmh.heap[par] = bmh.heap[par], bmh.heap[current_ind]
            end
            current_ind = par
        end
    end

end
