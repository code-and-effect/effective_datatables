class EffectiveStyleGuideDatatable < Effective::Datatable
  datatable do
    length 10

    col :id
    col :material, search: { collection: ['Stainless Steel', 'Copper', 'Cast Iron', 'Composite'] }
    col :bowl, search: { collection: ['Single Bowl', 'Double Bowl', 'Triple Bowl'] }
    col :name
    col :date, as: :date
  end

  # Set the permission check to the same as Effective::StyleGuide
  def collection_class
    defined?(Effective::StyleGuide) ? Effective::StyleGuide : super
  end

  collection do
    now = Time.zone.now
    [
      [1, 'Stainless Steel', 'Single Bowl', 'KOHLER Staccato', (now + 1.day)],
      [2, 'Stainless Steel', 'Double Bowl', 'KOHLER Vault Undercounter', (now + 1.day)],
      [3, 'Stainless Steel', 'Triple Bowl', 'KRAUS All-In-One', (now + 1.day)],
      [4, 'Stainless Steel', 'Single Bowl', 'KOHLER Vault Dual Mount', (now + 1.day)],
      [5, 'Stainless Steel', 'Single Bowl', 'KRAUS All-In-One Undermount', (now + 2.days)],
      [6, 'Stainless Steel', 'Double Bowl', 'Glacier Bay All-in-One', (now + 2.days)],
      [7, 'Stainless Steel', 'Single Bowl', 'Elkay Neptune', (now + 2.days)],
      [8, 'Copper', 'Single Bowl', 'ECOSINKS Apron Front Dual Mount', (now + 2.days)],
      [9, 'Copper', 'Double Bowl', 'ECOSINKS Dual Mount Front Hammered', (now + 2.days)],
      [10, 'Copper', 'Triple Bowl', 'Glarier Bay Undermount', (now + 3.days)],
      [11, 'Copper', 'Single Bowl', 'Whitehaus Undermount', (now + 3.days)],
      [12, 'Copper', 'Double Bowl', 'Belle Foret Apron Front', (now + 3.days)],
      [13, 'Copper', 'Double Bowl', 'Pegasus Dual Mount', (now + 3.days)],
      [14, 'Cast Iron', 'Double Bowl', 'KOHLER Whitehaven', (now + 3.days)],
      [15, 'Cast Iron', 'Triple Bowl', 'KOHLER Hartland', (now + 3.days)],
      [16, 'Cast Iron', 'Single Bowl', 'KOHLER Cape Dory Undercounter', (now + 4.days)],
      [17, 'Cast Iron', 'Double Bowl', 'KOLER Bakersfield', (now + 4.days)],
      [18, 'Cast Iron', 'Double Bowl', 'American Standard Offset', (now + 4.days)],
      [19, 'Cast Iron', 'Single Bowl', 'Brookfield Top', (now + 4.days)],
      [20, 'Composite', 'Single Bowl', 'Blanco Diamond Undermount', (now + 5.days)],
      [21, 'Composite', 'Double Bowl', 'Mont Blanc Waterbrook', (now + 5.days)],
      [22, 'Composite', 'Triple Bowl', 'Pegasus Triple Mount', (now + 5.days)],
      [23, 'Composite', 'Single Bowl', 'Swanstone Dual Mount', (now + 5.days)]
    ]
  end
end
