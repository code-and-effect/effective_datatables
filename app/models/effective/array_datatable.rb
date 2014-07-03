module Effective
  # The collection is an Array of Arrays
  module ArrayDatatable
    def array_order(collection)
      if order_direction == 'ASC'
        collection.sort { |x, y| x[order_column] <=> y[order_column] }
      else
        collection.sort { |x, y| y[order_column] <=> x[order_column] }
      end
    end

    def array_search(collection)
      collection.select { |row| row.any? { |value| value.to_s.include?(search_term) } }
    end

    def array_paginate(collection)
      Kaminari.paginate_array(collection).page(page).per(per_page)
    end

    def array_arrayize(collection)
      collection
    end
  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]
