import React from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../contexts/CartContext';

const ProductCard = ({ product }) => {
  const { addItem, isInCart } = useCart();

  const handleAddToCart = (e) => {
    e.preventDefault();
    addItem(product, 1);
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  return (
    <div className="group">
      <Link to={`/products/${product._id}`} className="block">
        <div className="bg-white rounded-lg shadow-sm hover:shadow-lg transition-shadow overflow-hidden">
          {/* Product Image */}
          <div className="aspect-w-1 aspect-h-1 bg-gray-200 overflow-hidden">
            <img
              src={product.primaryImage || product.images?.[0]?.url || '/placeholder-product.jpg'}
              alt={product.name}
              className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-300"
            />
            {product.discountPercentage > 0 && (
              <div className="absolute top-2 left-2 bg-red-500 text-white px-2 py-1 rounded text-sm font-semibold">
                -{product.discountPercentage}%
              </div>
            )}
          </div>

          {/* Product Info */}
          <div className="p-4">
            <h3 className="font-semibold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-2">
              {product.name}
            </h3>
            
            <div className="mt-2">
              <div className="flex items-center space-x-2">
                <span className="text-lg font-bold text-gray-900">
                  {formatPrice(product.price)}
                </span>
                {product.originalPrice && product.originalPrice > product.price && (
                  <span className="text-sm text-gray-500 line-through">
                    {formatPrice(product.originalPrice)}
                  </span>
                )}
              </div>
            </div>

            {/* Rating */}
            {product.rating?.average > 0 && (
              <div className="flex items-center mt-2">
                <div className="flex items-center">
                  {[...Array(5)].map((_, i) => (
                    <svg
                      key={i}
                      className={`w-4 h-4 ${
                        i < Math.floor(product.rating.average)
                          ? 'text-yellow-400'
                          : 'text-gray-300'
                      }`}
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                </div>
                <span className="text-sm text-gray-500 ml-1">
                  ({product.rating.count})
                </span>
              </div>
            )}

            {/* Stock Status */}
            <div className="mt-2">
              {product.stockStatus === 'out_of_stock' ? (
                <span className="text-sm text-red-600 font-medium">Out of Stock</span>
              ) : product.stockStatus === 'low_stock' ? (
                <span className="text-sm text-yellow-600 font-medium">Low Stock</span>
              ) : (
                <span className="text-sm text-green-600 font-medium">In Stock</span>
              )}
            </div>

            {/* Add to Cart Button */}
            <div className="mt-4">
              {product.stockStatus === 'out_of_stock' ? (
                <button
                  disabled
                  className="w-full bg-gray-300 text-gray-500 py-2 px-4 rounded-md font-medium cursor-not-allowed"
                >
                  Out of Stock
                </button>
              ) : isInCart(product._id) ? (
                <Link
                  to="/cart"
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-md font-medium hover:bg-blue-700 transition-colors text-center block"
                >
                  View in Cart
                </Link>
              ) : (
                <button
                  onClick={handleAddToCart}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-md font-medium hover:bg-blue-700 transition-colors"
                >
                  Add to Cart
                </button>
              )}
            </div>
          </div>
        </div>
      </Link>
    </div>
  );
};

export default ProductCard;
