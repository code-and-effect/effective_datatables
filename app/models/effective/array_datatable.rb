module Effective
  # The collection is an Array of Arrays
  module ArrayDatatable
    def order(collection)
      if order_direction == 'ASC'
        collection.sort { |x, y| x[order_column] <=> y[order_column] }
      else
        collection.sort { |x, y| y[order_column] <=> x[order_column] }
      end
    end

    def search(collection)
      collection.select { |row| row.any? { |value| value.to_s.include?(search_term) } }
    end

    def paginate(collection)
      Kaminari.paginate_array(collection).page(page).per(per_page)
    end

    def arrayize(collection)
      collection
    end
  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]
