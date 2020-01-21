module Vinclude

using Printf

export vinclude, tinclude

# jdad's include with verbose, like source(...,verbose=true) in R

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

# utilitie : prettytime / from BenchmarkTools
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



function vinclude(filetoinc::AbstractString ;debug=false, timed=false, logfile=nothing)
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
	tf=td
	dt=tf-td
    while true
        #write(repl.terminal, JULIA_PROMPT)
		ps=""
		#td=time_ns()*scalet
		if timed
		    ps=@sprintf("%9.6f/%9.6f",dt,td)
		end
		ps1= ps * xps1
		ps2= ps * xps2
        line = ""
        ast = nothing
        interrupted = false
		lined=""
		lines=""
		firstline = true
        while true
            try
	        debug && write(stdout,"\n$il linebefor="*line)
            oneline = readline(f, keep=true)
			line = line * oneline
			if firstline
			    lined = oneline
				firstline = false
				write(stdout, ps1 * oneline)
			else
			    lines= lines * oneline
				write(stdout, ps2 * oneline)
				#ends_with_newline(line) || write(stdout, '\n')
			end
			ends_with_newline(oneline) || write(stdout, '\n')
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
	    (ile>0) && (il > ile) && @info "jdincl : max $ilx number of lines in expr reached" && break
	    (ilx>0) && (il > ilx) && @info "jdincl : max $ilx number of lines to process reached" && break
        end
        ast = Base.parse_input_line(line)
        #(isa(ast,Expr) && ast.head == :incomplete) && @info "east : expr is incomplete"
	#debug && @show isa(ast,Expr)
	#debug && @show ast.head
        #if !isempty(line)
        if isa(ast,Expr)
	        debug && write(stdout,"evaling=")
	        #write(stdout,line)
            #ends_with_newline(line) || write(stdout, '\n')
	        line_to_eval=line
	        #if(timed)
	        #  line_to_eval="@time " * line
	        #  print("\n timing $line_to_eval\n")
	        #end
            #eval(line_to_eval)
			td=(time_ns()-t0)*scalet
            include_string(Main,line_to_eval)
			tf=(time_ns()-t0)*scalet
			dt=tf-td
	        debug && write(stdout,"...evaling complete.")
            #eval("ans="*line)
            if !ends_with_semicolon(line)
	        debug && write(stdout,"...should output response?")
		    #@show ans
                # print_response(repl, val, bt, true, false)
            end
        else
			debug && write(stdout,"not_an expr-ignoring=")
			#write(stdout,line)
            #ends_with_newline(line) || write(stdout, '\n')
        end
        #write(stdout, '\n')
        #ends_with_newline(line) || write(stdout, '\n')
        ((!interrupted && isempty(line)) || hit_eof) && break
	(ilx>0) && (il > ilx) && @info "jdincl : max $ilx number of lines to process reached" && break
    end
  end
    # terminate backend
    nothing
end

tinclude(filetoinc::AbstractString ;debug=false, logfile=nothing) = vinclude(filetoinc; debug=debug, timed=true, logfile=logfile)

function test_vinclude()
  testfiletoinc = joinpath(homedir(),"jl","julia-beks1.jl")
  vinclude(testfiletoinc)
  s=10
  #@show "jdincl - done - sleeping $s"
  sleep(s)
  #@show "jdincl - quit"
end

end # module
