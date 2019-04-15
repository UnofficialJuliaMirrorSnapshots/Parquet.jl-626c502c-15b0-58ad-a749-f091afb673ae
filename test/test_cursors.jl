using Parquet
using Test

function test_col_cursor(file::String, parcompat::String=joinpath(dirname(@__FILE__), "parquet-compatibility"))
    p = ParFile(joinpath(parcompat, file))
    println("loaded ", file)

    nr = nrows(p)
    cnames = colnames(p)
    for cname in cnames
        rr = 1:nr
        println("\tcolumn ", cname, " rows:", rr)
        println("\tvalue, defn, repn, next idx")
        t1 = time()
        cc = ColCursor(p, rr, cname)
        num_read = 0
        for (v,i) in enumerate(cc)
            val,defn,repn = v
            num_read += 1
        end
        println("\t\t", isnull(val) ? nothing : get(val), ", ", defn, ", ", repn, ", ", i)
        println("\t\tread $num_read values in $(time()-t1) time")
    end
end

function test_juliabuilder_row_cursor(file::String, typename::Symbol, parcompat::String=joinpath(dirname(@__FILE__), "parquet-compatibility"))
    p = ParFile(joinpath(parcompat, file))
    println("loaded ", file)

    t1 = time()
    nr = nrows(p)
    cnames = colnames(p)
    schema(JuliaConverter(Main), p, typename)
    jb = JuliaBuilder(p, getfield(Main, typename))
    rc = RecCursor(p, 1:nr, colnames(p), jb)
    rec = nothing
    for i in rc
        rec = i
    end
    println("\t\tlast record: $rec")
    println("\t\tread $nr records in $(time()-t1) time")
end

function test_col_cursor_all_files()
    for encformat in ("SNAPPY", "GZIP", "NONE")
        for fname in ("nation", "customer")
            test_col_cursor("parquet-testdata/impala/1.1.1-$encformat/$fname.impala.parquet")
        end
    end
end

function test_juliabuilder_row_cursor_all_files()
    for encformat in ("SNAPPY", "GZIP", "NONE")
        for fname in ("nation", "customer")
            test_juliabuilder_row_cursor("parquet-testdata/impala/1.1.1-$encformat/$fname.impala.parquet", Symbol(encformat * fname))
        end
    end
end

#test_col_cursor_all_files()
test_juliabuilder_row_cursor_all_files()
