const express = require('express');
const { body, validationResult, query } = require('express-validator');
const Category = require('../models/Category');
const { auth, adminOrModeratorAuth } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// @route   GET /api/categories
// @desc    Get all categories
// @access  Public
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('parent').optional().isMongoId().withMessage('Invalid parent category ID'),
  query('level').optional().isInt({ min: 0 }).withMessage('Level must be a non-negative integer'),
  query('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
  query('featured').optional().isBoolean().withMessage('featured must be a boolean'),
  query('sortBy').optional().isIn(['name', 'sortOrder', 'createdAt', 'productCount']).withMessage('Invalid sort field'),
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
      parent,
      level,
      isActive = true,
      featured,
      sortBy = 'sortOrder',
      sortOrder = 'asc'
    } = req.query;

    // Build query
    const query = {};

    if (parent !== undefined) {
      query.parent = parent || null;
    }

    if (level !== undefined) {
      query.level = parseInt(level);
    }

    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    if (featured !== undefined) {
      query.isFeatured = featured === 'true';
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

    // Get categories
    const categories = await Category.find(query)
      .populate('parent', 'name slug')
      .populate('createdBy', 'firstName lastName')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await Category.countDocuments(query);

    // Calculate pagination info
    const totalPages = Math.ceil(total / parseInt(limit));
    const hasNextPage = parseInt(page) < totalPages;
    const hasPrevPage = parseInt(page) > 1;

    res.json({
      success: true,
      data: {
        categories,
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
    logger.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/categories/tree
// @desc    Get category tree
// @access  Public
router.get('/tree', async (req, res) => {
  try {
    const categories = await Category.getTree();

    // Build tree structure
    const buildTree = (categories, parentId = null) => {
      return categories
        .filter(category => category.parent?.toString() === parentId?.toString())
        .map(category => ({
          ...category,
          children: buildTree(categories, category._id)
        }));
    };

    const tree = buildTree(categories);

    res.json({
      success: true,
      data: { categories: tree }
    });

  } catch (error) {
    logger.error('Get category tree error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/categories/featured
// @desc    Get featured categories
// @access  Public
router.get('/featured', [
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50')
], async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const categories = await Category.getFeatured(parseInt(limit));

    res.json({
      success: true,
      data: { categories }
    });

  } catch (error) {
    logger.error('Get featured categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/categories/:id
// @desc    Get category by ID
// @access  Public
router.get('/:id', [
  body('id').isMongoId().withMessage('Invalid category ID')
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

    const category = await Category.findById(id)
      .populate('parent', 'name slug')
      .populate('createdBy', 'firstName lastName')
      .populate('updatedBy', 'firstName lastName');

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Only show active categories to non-admin users
    if (!category.isActive && (!req.user || req.user.role !== 'admin')) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      data: { category }
    });

  } catch (error) {
    logger.error('Get category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/categories/:id/breadcrumb
// @desc    Get category breadcrumb
// @access  Public
router.get('/:id/breadcrumb', [
  body('id').isMongoId().withMessage('Invalid category ID')
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

    const breadcrumb = await Category.getBreadcrumb(id);

    res.json({
      success: true,
      data: { breadcrumb }
    });

  } catch (error) {
    logger.error('Get category breadcrumb error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/categories
// @desc    Create new category
// @access  Private (Admin/Moderator)
router.post('/', [
  auth,
  adminOrModeratorAuth,
  body('name')
    .notEmpty()
    .withMessage('Category name is required')
    .isLength({ max: 50 })
    .withMessage('Category name cannot exceed 50 characters'),
  body('description')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Category description cannot exceed 500 characters'),
  body('parent')
    .optional()
    .isMongoId()
    .withMessage('Invalid parent category ID'),
  body('image')
    .optional()
    .isObject()
    .withMessage('Image must be an object'),
  body('image.url')
    .optional()
    .isURL()
    .withMessage('Image URL must be valid'),
  body('color')
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Color must be a valid hex color'),
  body('isFeatured')
    .optional()
    .isBoolean()
    .withMessage('isFeatured must be a boolean'),
  body('sortOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Sort order must be a non-negative integer')
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
      name,
      description,
      parent,
      image,
      icon,
      color,
      isFeatured,
      sortOrder,
      seoTitle,
      seoDescription,
      seoKeywords
    } = req.body;

    // Validate parent category if provided
    if (parent) {
      const parentCategory = await Category.findById(parent);
      if (!parentCategory) {
        return res.status(400).json({
          success: false,
          message: 'Parent category not found'
        });
      }

      // Validate hierarchy
      await Category.validateHierarchy(null, parent);
    }

    // Check if category name already exists
    const existingCategory = await Category.findOne({ name });
    if (existingCategory) {
      return res.status(400).json({
        success: false,
        message: 'Category name already exists'
      });
    }

    // Create category
    const category = new Category({
      name,
      description,
      parent,
      image,
      icon: icon || 'folder',
      color: color || '#6B7280',
      isFeatured: isFeatured || false,
      sortOrder: sortOrder || 0,
      seoTitle,
      seoDescription,
      seoKeywords: seoKeywords || [],
      createdBy: req.user.id
    });

    await category.save();

    // Populate the created category
    await category.populate('parent', 'name slug');
    await category.populate('createdBy', 'firstName lastName');

    logger.info(`Category created: ${category.name} by ${req.user.email}`);

    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: { category }
    });

  } catch (error) {
    logger.error('Create category error:', error);
    
    if (error.message.includes('hierarchy')) {
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

// @route   PUT /api/categories/:id
// @desc    Update category
// @access  Private (Admin/Moderator)
router.put('/:id', [
  auth,
  adminOrModeratorAuth,
  body('id').isMongoId().withMessage('Invalid category ID'),
  body('name')
    .optional()
    .isLength({ max: 50 })
    .withMessage('Category name cannot exceed 50 characters'),
  body('description')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Category description cannot exceed 500 characters'),
  body('parent')
    .optional()
    .isMongoId()
    .withMessage('Invalid parent category ID'),
  body('color')
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Color must be a valid hex color'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean'),
  body('isFeatured')
    .optional()
    .isBoolean()
    .withMessage('isFeatured must be a boolean'),
  body('sortOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Sort order must be a non-negative integer')
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
    const updateData = req.body;

    // Validate parent category if being updated
    if (updateData.parent !== undefined) {
      if (updateData.parent) {
        const parentCategory = await Category.findById(updateData.parent);
        if (!parentCategory) {
          return res.status(400).json({
            success: false,
            message: 'Parent category not found'
          });
        }

        // Validate hierarchy
        await Category.validateHierarchy(id, updateData.parent);
      }
    }

    // Check if category name already exists (excluding current category)
    if (updateData.name) {
      const existingCategory = await Category.findOne({ 
        name: updateData.name, 
        _id: { $ne: id } 
      });
      if (existingCategory) {
        return res.status(400).json({
          success: false,
          message: 'Category name already exists'
        });
      }
    }

    updateData.updatedBy = req.user.id;

    const category = await Category.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    )
      .populate('parent', 'name slug')
      .populate('createdBy', 'firstName lastName')
      .populate('updatedBy', 'firstName lastName');

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    logger.info(`Category updated: ${category.name} by ${req.user.email}`);

    res.json({
      success: true,
      message: 'Category updated successfully',
      data: { category }
    });

  } catch (error) {
    logger.error('Update category error:', error);
    
    if (error.message.includes('hierarchy')) {
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

// @route   DELETE /api/categories/:id
// @desc    Delete category
// @access  Private (Admin only)
router.delete('/:id', [
  auth,
  adminOrModeratorAuth,
  body('id').isMongoId().withMessage('Invalid category ID')
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

    const category = await Category.findById(id);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Check if category has children
    const children = await Category.find({ parent: id });
    if (children.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete category with subcategories'
      });
    }

    // Check if category has products
    if (category.productCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete category with products'
      });
    }

    await Category.findByIdAndDelete(id);

    logger.info(`Category deleted: ${category.name} by ${req.user.email}`);

    res.json({
      success: true,
      message: 'Category deleted successfully'
    });

  } catch (error) {
    logger.error('Delete category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
