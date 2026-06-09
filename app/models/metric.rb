class Metric < ApplicationRecord
  DATA_TYPES = %w[decimal integer percentage boolean enumeration text].freeze
  NUMERIC_TYPES = %w[decimal integer percentage].freeze

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
