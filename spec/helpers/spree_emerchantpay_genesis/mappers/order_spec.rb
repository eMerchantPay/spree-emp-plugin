RSpec.describe SpreeEmerchantpayGenesis::Mappers::Order do
  let(:order) { create(:order_with_line_items) }
  let(:user) { create(:user) }
  let(:gateway_options) do
    build(
      :gateway_options_with_address,
      email: 'some@example.com',
      currency: 'EUR',
      order_number: 'O', payment_number: 'P'
    )
  end

  describe 'when prepare data' do
    let(:prepared_data) { described_class.prepare_data order, user, gateway_options }

    it 'with proper response' do
      expect(prepared_data).to be_kind_of Hash
    end

    it 'with order data' do
      expect(prepared_data[:number]).to_not be_nil
    end

    it 'with user data' do
      expect(prepared_data[:user]).to be_kind_of Hash
    end

    it 'with digital property' do
      expect(prepared_data[:digital]).to eq false
    end

    it 'with line items' do
      expect(prepared_data[:line_items]).to be_kind_of Array
    end

    it 'with fake line item' do
      expect(prepared_data[:line_items].count).to be 1
    end

    it 'with billing address' do
      expect(prepared_data[:billing_address][:name]).to eq 'John Smith'
    end

    it 'with shipping address' do
      expect(prepared_data[:shipping_address][:name]).to eq 'John Smith'
    end
  end

  describe 'when order mapper' do
    describe 'when sample order' do
      let(:order) { create(:order) }
      let(:mapped_order) { described_class.for described_class.prepare_data(order, nil, {}) }

      it 'with proper response' do
        expect(mapped_order).to be_kind_of Hash
      end

      it 'with order data' do
        expect(mapped_order[:number]).to_not be_nil
      end

      it 'without line items' do
        expect(mapped_order[:line_items]).to be_empty
      end

      it 'without user' do
        expect(mapped_order[:user]).to be_empty
      end
    end

    describe 'when full data' do
      let(:mapped_order) { described_class.for described_class.prepare_data(order, user, gateway_options) }

      it 'with line items' do
        expect(mapped_order[:line_items].first[:quantity]).to eq 1
      end

      it 'with billing first name' do
        expect(mapped_order[:billing_address][:first_name]).to eq 'John'
      end

      it 'with billing last name' do
        expect(mapped_order[:billing_address][:last_name]).to eq 'Smith'
      end

      it 'with shipping first name' do
        expect(mapped_order[:shipping_address][:first_name]).to eq 'John'
      end

      it 'with shipping last name' do
        expect(mapped_order[:shipping_address][:last_name]).to eq 'Smith'
      end

      it 'with user' do
        expect(mapped_order[:user][:email]).to_not be_empty
      end
    end
  end
end
