/**************************************************************************
 * @sorting @algorithms
 **************************************************************************/



Array.Prototype.DefineProp('SortAscending',                 {Call: __InsertionSortAscending})   ; default ascending sort
Array.Prototype.DefineProp('SortDescending',                {Call: __InsertionSortDescending})  ; default descending sort
Array.Prototype.DefineProp('BubbleSortAscending',           {Call: __BubbleSortAscending})
Array.Prototype.DefineProp('BubbleSortDescending',          {Call: __BubbleSortDescending})
Array.Prototype.DefineProp('InsertionSortAscending',        {Call: __InsertionSortAscending})
Array.Prototype.DefineProp('InsertionSortDescending',       {Call: __InsertionSortDescending})
Array.Prototype.DefineProp('QuickSortAscending',            {Call: __QuickSortAscending})
Array.Prototype.DefineProp('QuickSortDescending',           {Call: __QuickSortDescending})
Array.Prototype.DefineProp('QuickSortAscendingRecursion',   {Call: __QuickSortAscendingRecursion})
Array.Prototype.DefineProp('QuickSortDescendingRecursion',  {Call: __QuickSortDescendingRecursion})



/**
 * @param @property {string} by default, it will sort an array by its values, but you can specify a property
 * if the array is made up of objects with a specific property
 */
__BubbleSortAscending(this, property := '')
{
    i := 0
    length := this.Length

    while true
    {
        swapped := false

        while ++i < length
        {
            if (property ? this[i].%property% > this[i+1].%property%    ; if property stated, use property value
                         : this[i] > this[i+1])                         ; if property omitted, use index value
            {
                temp      := this[i]
                this[i]   := this[i+1]
                this[i+1] := temp
                swapped   := true
            }
        }
        i := 0, length--

        if not swapped
            break
    }
}



/**
 * @param @property {string} by default, it will sort an array by its values, but you can specify a property
 * if the array is made up of objects with a specific property
 */
__BubbleSortDescending(this, property := '')
{
    i := 0
    n := this.Length

    while true
    {
        swapped := false

        while ++i < n
        {
            if (property ? this[i].%property% < this[i+1].%property%    ; if property stated, use property value
                         : this[i] < this[i+1])                         ; if property omitted, use index value
            {
                temp      := this[i]
                this[i]   := this[i+1]
                this[i+1] := temp
                swapped   := true
            }
        }
        i := 0, n--

        if not swapped
            break
    }
}



/**
 * @source https://github.com/Sampsca/PS-BAM/blob/master/lib/quick_sort_array_no_recursion.ahk
 */
__QuickSortAscending(this)
{
	stack       := []
	pivot       := 0
	pivotIndex  := 1
	leftIndex   := pivotIndex+1
	rightIndex  := this.Length

	stack.Push(pivotIndex) ; push always with left and right
	stack.Push(rightIndex)

	leftIndexOfSubSet := rightIndexOfSubset := 0

	while (stack.Length > 0)
    {
		rightIndexOfSubset := stack.Pop() ; pop always with right and left
		leftIndexOfSubSet  := stack.Pop()

		leftIndex  := leftIndexOfSubSet + 1
		pivotIndex := leftIndexOfSubSet
		rightIndex := rightIndexOfSubset

		pivot := this[pivotIndex]

		if (leftIndex > rightIndex)
            continue

		while (leftIndex < rightIndex)
        {
			while (leftIndex <= rightIndex) && (this[leftIndex] <= pivot)
				leftIndex++	                ; increment right to find the greater element than the pivot

			while (leftIndex <= rightIndex) && (this[rightIndex] >= pivot)
				rightIndex--                ; decrement right to find the smaller element than the pivot

			if (rightIndex >= leftIndex)    ; if right index is greater then only swap
				SwapElement(leftIndex, rightIndex)
        }

		if (pivotIndex <= rightIndex)
			if (this[pivotIndex] > this[rightIndex])
				SwapElement(pivotIndex, rightIndex)

		if (leftIndexOfSubSet < rightIndex) {
			stack.Push(leftIndexOfSubSet)
			stack.Push(rightIndex - 1)
        }

		if (rightIndexOfSubset > rightIndex) {
			stack.Push(rightIndex + 1)
			stack.Push(rightIndexOfSubset)
        }
    }
	return this


    SwapElement(left, right)
    {
        temp        := this[left]
        this[left]  := this[right]
        this[right] := temp
    }
}



__QuickSortDescending(this) {
    __QuickSortAscending(this)
    this.Reverse()
}



/**
 * current iterations of quick sort are limited to the function recursion limit
 * don't use on larger arrays
 */
__QuickSortAscendingRecursion(this) => __QuickSortMainAscending(this, 1, this.Length)
__QuickSortMainAscending(this, start := 1, end := this.Length) ; Ascending
{
    if start < end
    {
        p := Partition(start, end)
        ; this.QuickSortAscendingRecursion(start, p-1)
        ; this.QuickSortAscendingRecursion(p+1, end)
    }

    Partition(start, end)  ; quick sort
    {
        pivot := this[end]

        i := (start - 1)
        j := start

        while j < end
        {
            if this[j] < pivot
            {
                i++
                t := this[i]
                this[i] := this[j]
                this[j] := t
            }
            j++
        }

        i++
        this[end] := this[i]
        this[i] := pivot
        return i
    }
}



/**
 * current iterations of quick sort are limited to the function recursion limit
 * don't use on larger arrays
 */
__QuickSortDescendingRecursion(this) => __QuickSortMainDescending(this, 1, this.Length)
__QuickSortMainDescending(this, start, end) ; descending
{
    if start < end {
        p := QuickSortAuxillary(this, start, end)
        __QuickSortMainDescending(this, start, p-1)
        __QuickSortMainDescending(this, p+1, end)
    }

    QuickSortAuxillary(this, start, end)  ; quick sort
    {
        pivot := this[end]

        i := (start - 1)
        j := start

        while j <= end - 1
        {
            if this[j] > pivot
            {
                i++
                t := this[i]
                this[i] := this[j]
                this[j] := t
            }
            j++
        }
        t := this[i+1]
        this[i+1] := this[end]
        this[end] := t
        return i+1
    }
}



/**
 * @insertionsort
 */
__InsertionSortAscending(this)
{
    i := 2

    while (i <= this.Length)
    {
        value := this[i]
        j := i - 1
        while (j >= 1 and this[j] > value) {
            this[j + 1] := this[j]
            j--
        }
        this[j + 1] := value
        i++
    }
}



/**
 * @insertionsort
 */
__InsertionSortDescending(this)
{
    i := 2

    while (i <= this.Length)
    {
        value := this[i]
        j := i - 1
        while (j >= 1 and this[j] < value) {
            this[j + 1] := this[j]
            j--
        }
        this[j + 1] := value
        i++
    }
}