const express = require('express');
const { body, validationResult, query } = require('express-validator');
const Order = require('../models/Order');
const Product = require('../models/Product');
const { auth, adminOrModeratorAuth } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// @route   GET /api/orders
// @desc    Get all orders
// @access  Private
router.get('/', [
  auth,
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned']).withMessage('Invalid status'),
  query('paymentStatus').optional().isIn(['pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled']).withMessage('Invalid payment status'),
  query('sortBy').optional().isIn(['createdAt', 'orderNumber', 'pricing.total']).withMessage('Invalid sort field'),
  query('sortOrder').optional().isIn(['asc', 'desc']).withMessage('Sort order must be asc or desc')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const {
      page = 1,
      limit = 20,
      status,
      paymentStatus,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build query
    const query = {};

    // Non-admin users can only see their own orders
    if (req.user.role !== 'admin') {
      query.user = req.user.id;
    }

    if (status) {
      query.status = status;
    }

    if (paymentStatus) {
      query['payment.status'] = paymentStatus;
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

    // Get orders
    const orders = await Order.find(query)
      .populate('user', 'firstName lastName email')
      .populate('items.product', 'name images')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await Order.countDocuments(query);

    // Calculate pagination info
    const totalPages = Math.ceil(total / parseInt(limit));
    const hasNextPage = parseInt(page) < totalPages;
    const hasPrevPage = parseInt(page) > 1;

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
          hasNextPage,
          hasPrevPage
        }
      }
    });

  } catch (error) {
    logger.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/orders/stats
// @desc    Get order statistics
// @access  Private (Admin only)
router.get('/stats', [
  auth,
  adminOrModeratorAuth,
  query('startDate').optional().isISO8601().withMessage('Start date must be a valid ISO 8601 date'),
  query('endDate').optional().isISO8601().withMessage('End date must be a valid ISO 8601 date')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { startDate, endDate } = req.query;

    const stats = await Order.getStatistics(startDate, endDate);

    res.json({
      success: true,
      data: { stats }
    });

  } catch (error) {
    logger.error('Get order stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/orders/:id
// @desc    Get order by ID
// @access  Private
router.get('/:id', [
  auth,
  body('id').isMongoId().withMessage('Invalid order ID')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id } = req.params;

    const order = await Order.findById(id)
      .populate('user', 'firstName lastName email')
      .populate('items.product', 'name images');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if user can access this order
    if (req.user.role !== 'admin' && order.user._id.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: { order }
    });

  } catch (error) {
    logger.error('Get order error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/orders
// @desc    Create new order
// @access  Private
router.post('/', [
  auth,
  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required'),
  body('items.*.product')
    .isMongoId()
    .withMessage('Valid product ID is required'),
  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1'),
  body('shippingAddress')
    .isObject()
    .withMessage('Shipping address is required'),
  body('shippingAddress.firstName')
    .notEmpty()
    .withMessage('Shipping first name is required'),
  body('shippingAddress.lastName')
    .notEmpty()
    .withMessage('Shipping last name is required'),
  body('shippingAddress.address1')
    .notEmpty()
    .withMessage('Shipping address is required'),
  body('shippingAddress.city')
    .notEmpty()
    .withMessage('Shipping city is required'),
  body('shippingAddress.state')
    .notEmpty()
    .withMessage('Shipping state is required'),
  body('shippingAddress.postalCode')
    .notEmpty()
    .withMessage('Shipping postal code is required'),
  body('shippingAddress.country')
    .notEmpty()
    .withMessage('Shipping country is required'),
  body('billingAddress')
    .isObject()
    .withMessage('Billing address is required'),
  body('payment.method')
    .isIn(['credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer', 'cash_on_delivery'])
    .withMessage('Invalid payment method')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const {
      items,
      shippingAddress,
      billingAddress,
      payment,
      notes,
      isGift,
      giftMessage,
      coupon
    } = req.body;

    // Validate and process items
    const orderItems = [];
    let subtotal = 0;

    for (const item of items) {
      const product = await Product.findById(item.product);
      
      if (!product) {
        return res.status(400).json({
          success: false,
          message: `Product not found: ${item.product}`
        });
      }

      if (!product.isActive) {
        return res.status(400).json({
          success: false,
          message: `Product is not available: ${product.name}`
        });
      }

      if (product.stock < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock for product: ${product.name}`
        });
      }

      const itemTotal = product.price * item.quantity;
      subtotal += itemTotal;

      orderItems.push({
        product: product._id,
        productName: product.name,
        productImage: product.primaryImage,
        quantity: item.quantity,
        price: product.price,
        total: itemTotal,
        variant: item.variant || {}
      });
    }

    // Calculate pricing
    const tax = subtotal * 0.1; // 10% tax (this should be configurable)
    const shipping = subtotal > 100 ? 0 : 10; // Free shipping over $100
    const discount = 0; // This would be calculated based on coupon
    const total = subtotal + tax + shipping - discount;

    // Create order
    const order = new Order({
      user: req.user.id,
      items: orderItems,
      shippingAddress,
      billingAddress,
      payment: {
        method: payment.method,
        status: 'pending'
      },
      pricing: {
        subtotal,
        tax,
        shipping,
        discount,
        total
      },
      notes: {
        customer: notes?.customer || '',
        internal: notes?.internal || ''
      },
      isGift: isGift || false,
      giftMessage: giftMessage || '',
      coupon: coupon || null,
      source: 'web',
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    await order.save();

    // Update product stock
    for (const item of orderItems) {
      await Product.findByIdAndUpdate(
        item.product,
        { $inc: { stock: -item.quantity } }
      );
    }

    // Populate the created order
    await order.populate('user', 'firstName lastName email');
    await order.populate('items.product', 'name images');

    logger.info(`Order created: ${order.orderNumber} by ${req.user.email}`);

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: { order }
    });

  } catch (error) {
    logger.error('Create order error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/orders/:id/status
// @desc    Update order status
// @access  Private (Admin/Moderator)
router.put('/:id/status', [
  auth,
  adminOrModeratorAuth,
  body('id').isMongoId().withMessage('Invalid order ID'),
  body('status')
    .isIn(['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned'])
    .withMessage('Invalid status'),
  body('notes').optional().isString().withMessage('Notes must be a string')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const { status, notes } = req.body;

    const order = await Order.findById(id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Update status
    await order.updateStatus(status, notes);

    // Populate the updated order
    await order.populate('user', 'firstName lastName email');
    await order.populate('items.product', 'name images');

    logger.info(`Order status updated: ${order.orderNumber} to ${status} by ${req.user.email}`);

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: { order }
    });

  } catch (error) {
    logger.error('Update order status error:', error);
    
    if (error.message.includes('Invalid status transition')) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/orders/:id/tracking
// @desc    Add tracking information
// @access  Private (Admin/Moderator)
router.put('/:id/tracking', [
  auth,
  adminOrModeratorAuth,
  body('id').isMongoId().withMessage('Invalid order ID'),
  body('carrier')
    .notEmpty()
    .withMessage('Carrier is required'),
  body('trackingNumber')
    .notEmpty()
    .withMessage('Tracking number is required'),
  body('trackingUrl')
    .optional()
    .isURL()
    .withMessage('Tracking URL must be valid')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const { carrier, trackingNumber, trackingUrl } = req.body;

    const order = await Order.findById(id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Add tracking information
    await order.addTracking(carrier, trackingNumber, trackingUrl);

    // Populate the updated order
    await order.populate('user', 'firstName lastName email');
    await order.populate('items.product', 'name images');

    logger.info(`Tracking added to order: ${order.orderNumber} by ${req.user.email}`);

    res.json({
      success: true,
      message: 'Tracking information added successfully',
      data: { order }
    });

  } catch (error) {
    logger.error('Add tracking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/orders/:id/refund
// @desc    Process refund
// @access  Private (Admin only)
router.put('/:id/refund', [
  auth,
  adminOrModeratorAuth,
  body('id').isMongoId().withMessage('Invalid order ID'),
  body('amount')
    .isFloat({ min: 0.01 })
    .withMessage('Refund amount must be greater than 0'),
  body('reason')
    .optional()
    .isString()
    .withMessage('Reason must be a string')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const { amount, reason } = req.body;

    const order = await Order.findById(id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Process refund
    await order.processRefund(amount, reason);

    // Populate the updated order
    await order.populate('user', 'firstName lastName email');
    await order.populate('items.product', 'name images');

    logger.info(`Refund processed for order: ${order.orderNumber} by ${req.user.email}`);

    res.json({
      success: true,
      message: 'Refund processed successfully',
      data: { order }
    });

  } catch (error) {
    logger.error('Process refund error:', error);
    
    if (error.message.includes('Can only refund completed payments') || 
        error.message.includes('Refund amount cannot exceed order total')) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
