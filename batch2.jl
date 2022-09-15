using Knots.Links, Knots.Khovanov
using Knots.Extensions: GaussInt
using CSV
using DataFrames
using OrderedCollections

knots = OrderedDict(
    "18nh_09772775" => Link([[1, 17, 2, 16], [15, 1, 16, 36], [35, 8, 36, 9], [7, 15, 8, 14], [13, 7, 14, 6], [17, 13, 18, 12], [11, 2, 12, 3], [5, 34, 6, 35], [10, 26, 11, 25], [26, 10, 27, 9], [4, 28, 5, 27], [24, 4, 25, 3], [33, 20, 34, 21], [19, 32, 20, 33], [31, 18, 32, 19], [21, 28, 22, 29], [29, 22, 30, 23], [23, 30, 24, 31]]),
    "18nh_14077348" => Link([[1, 21, 2, 20], [21, 3, 22, 2], [19, 13, 20, 12], [13, 36, 14, 1], [35, 14, 36, 15], [3, 35, 4, 34], [15, 5, 16, 4], [25, 16, 26, 17], [26, 5, 27, 6], [33, 24, 34, 25], [6, 18, 7, 17], [18, 27, 19, 28], [11, 28, 12, 29], [29, 22, 30, 23], [23, 30, 24, 31], [7, 11, 8, 10], [31, 9, 32, 8], [9, 33, 10, 32]]),
    "18nh_15848180" => Link([[1, 15, 2, 14], [15, 1, 16, 36], [35, 2, 36, 3], [13, 30, 14, 31], [29, 12, 30, 13], [11, 16, 12, 17], [23, 35, 24, 34], [24, 3, 25, 4], [10, 25, 11, 26], [31, 23, 32, 22], [21, 29, 22, 28], [27, 21, 28, 20], [17, 27, 18, 26], [4, 10, 5, 9], [33, 8, 34, 9], [7, 32, 8, 33], [19, 6, 20, 7], [5, 18, 6, 19]]),
    "18nh_16042369" => Link([[1, 30, 2, 31], [29, 36, 30, 1], [35, 28, 36, 29], [27, 4, 28, 5], [3, 26, 4, 27], [25, 2, 26, 3], [15, 25, 16, 24], [5, 17, 6, 16], [14, 31, 15, 32], [6, 10, 7, 9], [8, 24, 9, 23], [22, 8, 23, 7], [10, 17, 11, 18], [34, 11, 35, 12], [18, 34, 19, 33], [32, 22, 33, 21], [12, 20, 13, 19], [20, 14, 21, 13]]),
    "18nh_16534554" => Link([[1, 8, 2, 9], [7, 28, 8, 29], [29, 1, 30, 36], [35, 7, 36, 6], [9, 31, 10, 30], [5, 11, 6, 10], [31, 2, 32, 3], [27, 32, 28, 33], [3, 20, 4, 21], [21, 4, 22, 5], [22, 12, 23, 11], [12, 20, 13, 19], [18, 23, 19, 24], [17, 35, 18, 34], [33, 17, 34, 16], [15, 25, 16, 24], [13, 27, 14, 26], [25, 15, 26, 14]]),
    "18nh_18744650" => Link([[1, 14, 2, 15], [15, 2, 16, 3], [3, 36, 4, 1], [9, 17, 10, 16], [17, 9, 18, 8], [13, 18, 14, 19], [7, 12, 8, 13], [19, 4, 20, 5], [5, 29, 6, 28], [27, 7, 28, 6], [20, 30, 21, 29], [30, 22, 31, 21], [35, 22, 36, 23], [31, 35, 32, 34], [33, 27, 34, 26], [25, 33, 26, 32], [11, 24, 12, 25], [23, 10, 24, 11]]),
    "18nh_20994587" => Link([[1, 9, 2, 8], [9, 3, 10, 2], [7, 17, 8, 16], [15, 11, 16, 10], [17, 36, 18, 1], [6, 31, 7, 32], [30, 36, 31, 35], [29, 18, 30, 19], [34, 5, 35, 6], [3, 29, 4, 28], [19, 5, 20, 4], [27, 21, 28, 20], [21, 14, 22, 15], [13, 26, 14, 27], [11, 22, 12, 23], [25, 12, 26, 13], [32, 23, 33, 24], [24, 33, 25, 34]]),
    "18nh_21222170" => Link([[1, 10, 2, 11], [9, 2, 10, 3], [3, 1, 4, 36], [4, 31, 5, 32], [30, 12, 31, 11], [12, 30, 13, 29], [28, 5, 29, 6], [19, 33, 20, 32], [27, 19, 28, 18], [33, 27, 34, 26], [35, 21, 36, 20], [25, 35, 26, 34], [21, 8, 22, 9], [17, 7, 18, 6], [7, 24, 8, 25], [13, 16, 14, 17], [23, 15, 24, 14], [15, 23, 16, 22]]),
    "18nh_22033965" => Link([[1, 9, 2, 8], [7, 1, 8, 36], [31, 7, 32, 6], [9, 31, 10, 30], [29, 2, 30, 3], [5, 10, 6, 11], [20, 4, 21, 3], [4, 20, 5, 19], [11, 18, 12, 19], [21, 28, 22, 29], [35, 23, 36, 22], [17, 33, 18, 32], [23, 16, 24, 17], [33, 24, 34, 25], [15, 34, 16, 35], [14, 27, 15, 28], [26, 13, 27, 14], [12, 25, 13, 26]]),
    "18nh_23345595" => Link([[1, 24, 2, 25], [25, 2, 26, 3], [23, 36, 24, 1], [33, 26, 34, 27], [27, 34, 28, 35], [35, 28, 36, 29], [3, 17, 4, 16], [15, 23, 16, 22], [21, 15, 22, 14], [20, 29, 21, 30], [6, 14, 7, 13], [4, 8, 5, 7], [12, 6, 13, 5], [8, 17, 9, 18], [32, 9, 33, 10], [18, 32, 19, 31], [10, 20, 11, 19], [30, 12, 31, 11]]),
    "18nh_23366096" => Link([[1, 28, 2, 29], [27, 9, 28, 8], [9, 3, 10, 2], [3, 11, 4, 10], [29, 4, 30, 5], [16, 6, 17, 5], [36, 18, 1, 17], [18, 36, 19, 35], [7, 34, 8, 35], [6, 20, 7, 19], [33, 27, 34, 26], [11, 33, 12, 32], [25, 12, 26, 13], [31, 24, 32, 25], [23, 30, 24, 31], [13, 20, 14, 21], [21, 14, 22, 15], [15, 22, 16, 23]]),
    "18nh_23976466" => Link([[1, 25, 2, 24], [23, 1, 24, 36], [35, 3, 36, 2], [15, 22, 16, 23], [21, 14, 22, 15], [25, 16, 26, 17], [8, 18, 9, 17], [34, 10, 35, 9], [3, 10, 4, 11], [11, 20, 12, 21], [19, 5, 20, 4], [18, 33, 19, 34], [7, 33, 8, 32], [31, 27, 32, 26], [13, 31, 14, 30], [29, 13, 30, 12], [27, 6, 28, 7], [5, 28, 6, 29]]),
    "18nh_25766136" => Link([[1, 31, 2, 30], [31, 3, 32, 2], [29, 20, 30, 21], [19, 1, 20, 36], [35, 28, 36, 29], [12, 22, 13, 21], [22, 12, 23, 11], [34, 14, 35, 13], [10, 34, 11, 33], [23, 32, 24, 33], [3, 25, 4, 24], [25, 19, 26, 18], [17, 4, 18, 5], [5, 26, 6, 27], [27, 6, 28, 7], [7, 14, 8, 15], [15, 8, 16, 9], [9, 16, 10, 17]]),
    "18nh_26738105" => Link([[1, 31, 2, 30], [29, 1, 30, 36], [35, 29, 36, 28], [9, 3, 10, 2], [3, 11, 4, 10], [27, 5, 28, 4], [11, 26, 12, 27], [5, 12, 6, 13], [25, 6, 26, 7], [34, 14, 35, 13], [7, 18, 8, 19], [17, 8, 18, 9], [24, 20, 25, 19], [20, 33, 21, 34], [16, 32, 17, 31], [32, 23, 33, 24], [14, 21, 15, 22], [22, 15, 23, 16]]),
    "18nh_29018841" => Link([[1, 17, 2, 16], [15, 8, 16, 9], [7, 1, 8, 36], [9, 2, 10, 3], [35, 14, 36, 15], [3, 34, 4, 35], [13, 5, 14, 4], [19, 7, 20, 6], [5, 21, 6, 20], [17, 29, 18, 28], [29, 19, 30, 18], [27, 10, 28, 11], [30, 21, 31, 22], [22, 12, 23, 11], [12, 31, 13, 32], [23, 26, 24, 27], [33, 25, 34, 24], [25, 33, 26, 32]]),
    "18nh_29199759" => Link([[1, 11, 2, 10], [9, 3, 10, 2], [3, 36, 4, 1], [27, 5, 28, 4], [11, 28, 12, 29], [5, 13, 6, 12], [13, 18, 14, 19], [19, 7, 20, 6], [29, 20, 30, 21], [21, 8, 22, 9], [7, 31, 8, 30], [22, 35, 23, 36], [34, 32, 35, 31], [14, 33, 15, 34], [32, 15, 33, 16], [26, 24, 27, 23], [24, 17, 25, 18], [16, 25, 17, 26]]),
    "18nh_29322817" => Link([[1, 31, 2, 30], [31, 3, 32, 2], [17, 32, 18, 33], [29, 16, 30, 17], [15, 28, 16, 29], [27, 1, 28, 36], [35, 14, 36, 15], [34, 8, 35, 7], [6, 34, 7, 33], [5, 19, 6, 18], [13, 9, 14, 8], [19, 12, 20, 13], [9, 20, 10, 21], [21, 26, 22, 27], [3, 22, 4, 23], [23, 4, 24, 5], [25, 11, 26, 10], [11, 25, 12, 24]]),
    "18nh_30157971" => Link([[1, 8, 2, 9], [7, 36, 8, 1], [9, 23, 10, 22], [23, 11, 24, 10], [11, 2, 12, 3], [27, 6, 28, 7], [35, 29, 36, 28], [5, 35, 6, 34], [12, 29, 13, 30], [30, 4, 31, 3], [4, 13, 5, 14], [21, 27, 22, 26], [33, 14, 34, 15], [15, 21, 16, 20], [19, 33, 20, 32], [31, 19, 32, 18], [17, 24, 18, 25], [25, 16, 26, 17]]),
    "18nh_30493418" => Link([[1, 9, 2, 8], [9, 3, 10, 2], [3, 28, 4, 29], [27, 36, 28, 1], [7, 27, 8, 26], [35, 6, 36, 7], [25, 11, 26, 10], [4, 16, 5, 15], [16, 6, 17, 5], [17, 35, 18, 34], [11, 19, 12, 18], [33, 13, 34, 12], [19, 32, 20, 33], [13, 20, 14, 21], [21, 14, 22, 15], [29, 22, 30, 23], [23, 30, 24, 31], [31, 24, 32, 25]]),
    "18nh_30646371" => Link([[1, 8, 2, 9], [7, 36, 8, 1], [30, 10, 31, 9], [2, 29, 3, 30], [10, 3, 11, 4], [24, 12, 25, 11], [12, 26, 13, 25], [4, 13, 5, 14], [14, 32, 15, 31], [6, 16, 7, 15], [32, 5, 33, 6], [16, 35, 17, 36], [28, 24, 29, 23], [22, 18, 23, 17], [18, 27, 19, 28], [26, 19, 27, 20], [20, 34, 21, 33], [34, 22, 35, 21]]),
    "18nh_32607237" => Link([[1, 35, 2, 34], [35, 28, 36, 29], [27, 36, 28, 1], [2, 8, 3, 7], [29, 9, 30, 8], [9, 27, 10, 26], [18, 4, 19, 3], [6, 20, 7, 19], [30, 17, 31, 18], [20, 33, 21, 34], [10, 21, 11, 22], [32, 11, 33, 12], [12, 6, 13, 5], [4, 14, 5, 13], [14, 31, 15, 32], [22, 25, 23, 26], [24, 16, 25, 15], [16, 24, 17, 23]]),
    "18nh_33531420" => Link([[1, 23, 2, 22], [21, 29, 22, 28], [29, 36, 30, 1], [35, 20, 36, 21], [27, 3, 28, 2], [19, 30, 20, 31], [18, 23, 19, 24], [24, 17, 25, 18], [25, 7, 26, 6], [5, 27, 6, 26], [7, 17, 8, 16], [31, 9, 32, 8], [15, 33, 16, 32], [9, 14, 10, 15], [33, 10, 34, 11], [13, 34, 14, 35], [3, 12, 4, 13], [11, 4, 12, 5]]),
    "18nh_34174391" => Link([[1, 28, 2, 29], [29, 2, 30, 3], [9, 31, 10, 30], [27, 9, 28, 8], [7, 27, 8, 26], [31, 19, 32, 18], [17, 10, 18, 11], [19, 7, 20, 6], [3, 17, 4, 16], [11, 32, 12, 33], [5, 12, 6, 13], [33, 5, 34, 4], [36, 15, 1, 16], [14, 26, 15, 25], [13, 20, 14, 21], [24, 21, 25, 22], [22, 36, 23, 35], [34, 24, 35, 23]]),
    "18nh_34472231" => Link([[1, 21, 2, 20], [31, 3, 32, 2], [21, 30, 22, 31], [3, 22, 4, 23], [23, 33, 24, 32], [19, 14, 20, 15], [13, 1, 14, 36], [29, 12, 30, 13], [24, 16, 25, 15], [16, 26, 17, 25], [11, 28, 12, 29], [26, 33, 27, 34], [27, 4, 28, 5], [34, 5, 35, 6], [35, 11, 36, 10], [6, 10, 7, 9], [8, 17, 9, 18], [18, 7, 19, 8]]),
    "18nh_35736677" => Link([[1, 26, 2, 27], [9, 2, 10, 3], [27, 9, 28, 8], [36, 7, 1, 8], [6, 35, 7, 36], [3, 18, 4, 19], [19, 29, 20, 28], [5, 21, 6, 20], [29, 4, 30, 5], [17, 30, 18, 31], [31, 10, 32, 11], [25, 32, 26, 33], [11, 25, 12, 24], [23, 17, 24, 16], [15, 23, 16, 22], [21, 15, 22, 14], [13, 35, 14, 34], [33, 13, 34, 12]]),
)

function run(name::String, L::Link; dir="", file="result.csv") :: Bool
    @time s_2  = s_c(L, 2; reduced=true)
    @time s_3  = s_c(L, 3; reduced=true)

    nontrivial = !(s_2 == s_3)
    
    @show name s_2 s_3

    result = DataFrame(
        name = name, 
        s_2 = s_2, 
        s_3 = s_3, 
        nontrivial = nontrivial
    )

    file = dir * file
    CSV.write(file, result; append = isfile(file))

    true
end

for (name, L) in knots
    next = run(name, L)
end

nothing