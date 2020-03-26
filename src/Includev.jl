module Includev
# jdad's include with verbose, like source(...,verbose=true) in R

using Printf
export includev, includeve

# Utilities : functions ends_with_semicolon, ends_with_newline

# Inspired from Base.chomp
function ends_with_newline(s::AbstractString)
    i = lastindex(s)
    (i < 1 || s[i] != '\n') && (return false)
    return true
    #(i < 1 || s[i] != '\n') && (return SubString(s, 1, i))
    #j = prevind(s,i)
    #(j < 1 || s[j] != '\r') && (return SubString(s, 1, j))
    #return SubString(s, 1, prevind(s,j))
end

# originally from julia-1.1.0/share/julia/stdlib/v1.1/REPL/src/REPL.jl
function ends_with_semicolon(line::AbstractString)
    match = findlast(isequal(';'), line)
    if match !== nothing
        # state for comment parser, assuming that the `;` isn't in a string or comment
        # so input like ";#" will still thwart this to give the wrong (anti-conservative) answer
        comment = false
        comment_start = false
        comment_close = false
        comment_multi = 0
        for c in line[(match + 1):end]
            if comment_multi > 0
                # handle nested multi-line comments
                if comment_close && c == '#'
                    comment_close = false
                    comment_multi -= 1
                elseif comment_start && c == '='
                    comment_start = false
                    comment_multi += 1
                else
                    comment_start = (c == '#')
                    comment_close = (c == '=')
                end
            elseif comment
                # handle line comments
                if c == '\r' || c == '\n'
                    comment = false
                end
            elseif comment_start
                # see what kind of comment this is
                comment_start = false
                if c == '='
                    comment_multi = 1
                else
                    comment = true
                end
            elseif c == '#'
                # start handling for a comment
                comment_start = true
            else
                # outside of a comment, encountering anything but whitespace
                # means the semi-colon was internal to the expression
                isspace(c) || return false
            end
        end
        return true
    end
    return false
end

# utility : prettytime / from BenchmarkTools
function prettytime(t)
    if t < 1e3
        value, units = t, "ns"
    elseif t < 1e6
        value, units = t / 1e3, "μs"
    elseif t < 1e9
        value, units = t / 1e6, "ms"
    else
        value, units = t / 1e9, "s"
    end
    return string(@sprintf("%.3f", value), " ", units)
end

# end utilities

"""
    includev(filetoinc::AbstractString; echo=true, elaps=false, logfile=nothing, debug=false)
    
"""
function includev(filetoinc::AbstractString; echo=true, elaps=false, logfile=nothing, debug=false)
  scalet=1.0e-9
  t0=time_ns()
  open(filetoinc) do f
    il=0
    ile=999
    ilx=9999
    hit_eof = false
    prompt=filetoinc * "> "
    xps1="> "
    xps2=". "
    td=(time_ns()-t0)*scalet
    tf=td; 
    dt=tf-td
    while true # 1
        ps=""
        #td=time_ns()*scalet
        if elaps
            ps=@sprintf("+%9.6f =%9.6f",dt,td)
        end
        ps1= ps * xps1
        ps2= ps * xps2
        line = ""
        ast = nothing
        interrupted = false
        lined=""
        lines=""
        firstline = true
        while true # 2
            try
            debug && write(stdout,"\n$il linebefor="*line)
            oneline = readline(f, keep=true)
            line = line * oneline
            if firstline
                lined = oneline
                firstline = false
                echo && write(stdout, ps1 * oneline)
            else
                lines= lines * oneline
                echo && write(stdout, ps2 * oneline)
            end
			if !ends_with_newline(oneline)
                echo && write(stdout, '\n')
			end
            debug && write(stdout,"\n$il lineafter="*line)
            il += 1
            catch e
                if isa(e,InterruptException)
                    try # raise the debugger if present
                        ccall(:jl_raise_debugger, Int, ())
                    catch
                    end
                    line = ""
                    interrupted = true
                    break
                elseif isa(e,EOFError)
                    hit_eof = true
                    break
                else
                    rethrow()
                end
            end
            ast = Base.parse_input_line(line)
            (isa(ast,Expr) && ast.head == :incomplete) || break
            debug && @show isa(ast,Expr)
            debug && @show ast.head
            (ile>0) && (il > ile) && @info "includev : max $ilx number of lines in expr reached" && break
            (ilx>0) && (il > ilx) && @info "includev : max $ilx number of lines to process reached" && break
        end # while true 2
		# Now we have (hopefully) a group of lines with complete expression
        ast = Base.parse_input_line(line)
        if isa(ast,Expr)
            debug && write(stdout,"evaling=")
            line_to_eval = line
            td = (time_ns()-t0)*scalet
            include_string(Main,line_to_eval)
            tf = (time_ns()-t0)*scalet
            dt = tf-td
            debug && write(stdout,"...evaling complete.")
            if !ends_with_semicolon(line)
            debug && write(stdout,"...should output response?") # no ans as of now
            end
        else
            debug && write(stdout,"not_an expr-ignoring=")
        end
        ((!interrupted && isempty(line)) || hit_eof) && break
        (ilx>0) && (il > ilx) && @info "includev : max $ilx number of lines to process reached" && break
    end # while true # 1
  end # do f
  # terminate backend
  # as of now,  do not get last ans as returned result
  # nothing
end # function

includeve(filetoinc::AbstractString ;echo=true, logfile=nothing, debug=false) = includev(filetoinc; echo=echo, elaps=true, logfile=logfile, debug=debug)

end # module
