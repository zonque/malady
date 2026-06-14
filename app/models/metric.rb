class Metric < ApplicationRecord
  DATA_TYPES = %w[decimal integer percentage boolean enumeration text text_block].freeze
  NUMERIC_TYPES = %w[decimal integer percentage].freeze

  # Convenience presets selectable on the new-metric form. Each expands into a
  # real data_type plus pre-filled config — no new column or DATA_TYPE needed.
  # "scale_0_5" is the existing "choice"/enumeration type seeded with 0..5.
  PRESETS = {
    "scale_0_5" => { data_type: "enumeration", enum_options: %w[0 1 2 3 4 5] }
  }.freeze

  belongs_to :user
  has_many :data_points, dependent: :destroy

  # Stored as a JSON-serialized text column so it works identically on
  # SQLite (dev/test) and PostgreSQL (production).
  # NOTE: `type: Array` is intentionally omitted — Rails 8.1's Type::Serialized
  # treats `Array.new` (i.e. `[]`) as the "default value" and serializes it to
  # nil, which violates the NOT NULL constraint. Without `type:`, the coder
  # correctly writes "[]" for empty arrays.
  serialize :enum_options, coder: JSON

  enum :data_type, DATA_TYPES.index_by(&:itself), validate: true

  after_initialize :ensure_enum_options_array

  before_validation :generate_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  # A Bootstrap Icons name (kebab-case). Constrained so it can't break out of the
  # `class="bi bi-#{icon}"` attribute it's rendered into. Optional.
  validates :icon, format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }, allow_blank: true
  validate :enum_options_present_for_enumeration

  scope :ordered, -> { order(:position, :id) }

  def numeric? = NUMERIC_TYPES.include?(data_type)
  def chartable? = numeric? || boolean?

  private

  def generate_slug
    self.slug ||= name.to_s.parameterize
  end

  def ensure_enum_options_array
    self.enum_options = [] unless enum_options.is_a?(Array)
  end

  def enum_options_present_for_enumeration
    return unless enumeration?
    if enum_options.blank? || enum_options.reject(&:blank?).empty?
      errors.add(:enum_options, "can't be blank")
    end
  end
end
